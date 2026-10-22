#!/usr/bin/env python3

from http.cookiejar import MozillaCookieJar
from requests import Session
from os import makedirs
from os.path import exists
from pywikibot import Site, Page, exceptions as wikiex
from threading import Thread, Lock
from queue import Queue

PAGES_FILEPATH = 'pages.txt'
LINES_FILEPATH = 'lines.txt'          # replaces diffs.txt
CACHE_DIR = '/tmp/wiktpages'
EDIT_SUMMARY = 'replace pos parameter with ng (semi-automated, manually assisted)'
NUM_THREADS = 16

# Thread‑safe storage for results
found = {}           # page -> list of (lineno, line_text)
found_lock = Lock()

def worker(work_queue, cookie_jar):
    """Fetch pages from queue, search for '|pos=', update global found dict, write cache."""
    # Create a fresh session with the shared cookie jar
    session = Session()
    session.cookies.update(cookie_jar)

    site = Site('en', 'wiktionary')
    site.requests_session = session

    while True:
        try:
            title, page = work_queue.get_nowait()
        except:
            return   # queue empty
        try:
            text = page.text
        except wikiex.Error as e:
            print(f"Error fetching {title}: {e}")
            work_queue.task_done()
            continue
        if not text:
            work_queue.task_done()
            continue

        lines_list = text.splitlines()
        page_hits = []   # (lineno, line_text) for lines with '|pos='

        for idx, line in enumerate(lines_list, start=1):
            if '|pos=' in line:
                page_hits.append((idx, line))

        # Update global results
        if page_hits:
            with found_lock:
                found[title] = page_hits

        # Write full text to cache (one line per line, i.e. just the raw text)
        cache_path = f"{CACHE_DIR}/{title.replace('/', '_')}.txt"
        try:
            with open(cache_path, 'w', encoding='utf-8') as f:
                f.write(text)
        except OSError as e:
            print(f"Failed to write cache for {title}: {e}")

        work_queue.task_done()


def fetch_contribs():
    """Collect all contributed page titles, search text via threads, write pages.txt and lines.txt."""
    # 1. Get distinct page titles from user contributions
    site = Site('en', 'wiktionary')
    print("Fetching list of contributed pages …")

    contribs = site.usercontribs(user='Bytekast', namespaces=0, total=None)
    if not contribs:
        print("No contributions found.")
        return
    pages = {c[0].title():c[0] for c in contribs}

    print(f"Found {len(pages)} distinct pages; processing them with {NUM_THREADS} threads...")

    # 2. Prepare cookie jar (each thread will get a copy)
    cookie_jar = MozillaCookieJar('cookies.txt')
    cookie_jar.load(ignore_discard=True, ignore_expires=True)

    # 3. Create cache directory
    makedirs(CACHE_DIR, exist_ok=True)

    # 4. Feed pages into a queue
    work_queue = Queue()
    for t, p in pages.items():
        work_queue.put((t, p))

    # 5. Launch threads
    threads = []
    for _ in range(NUM_THREADS):
        t = Thread(target=worker, args=(work_queue, cookie_jar))
        t.start()
        threads.append(t)

    # Wait for all work to be done
    work_queue.join()
    for t in threads:
        t.join()

    print(f"Threads finished. Found '|pos=' on {len(found)} pages.")

    # 6. Write pages.txt and lines.txt
    with open(PAGES_FILEPATH, 'w', encoding='utf-8') as pages_f, \
         open(LINES_FILEPATH, 'w', encoding='utf-8') as lines_f:
        for title in sorted(found.keys()):
            pages_f.write(f"{title}\n")
            lines_f.write(f"{title}\n")
            for lineno, line_text in found[title]:
                lines_f.write(f"\t{lineno}: {line_text}\n")
            lines_f.write('\n')

    print(f"Phase 1 done. Check {LINES_FILEPATH} and remove false positives from {PAGES_FILEPATH}.")
    print("Then run the script again to perform the replacements (still in test mode).")


def correct_contribs():
    """Read curated pages.txt, fetch text from cache, apply replacements."""
    # Load browser cookies (only needed if we fall back to network, but we use cache)
    cookie_jar = MozillaCookieJar('cookies.txt')
    cookie_jar.load(ignore_discard=True, ignore_expires=True)

    session = Session()
    session.cookies.update(cookie_jar)

    site = Site('en', 'wiktionary')
    site.requests_session = session

    # Read curated page list
    with open(PAGES_FILEPATH, 'r', encoding='utf-8') as f:
        pages_to_do = {line.strip() for line in f if line.strip()}

    if not pages_to_do:
        print("No pages to process.")
        return

    # Parse lines.txt → page -> list of line numbers (keeping the order)
    with open(LINES_FILEPATH, 'r', encoding='utf-8') as f:
        content = f.read()

    blocks = content.split('\n\n')
    linenos_map = {}
    for block in blocks:
        lines = block.splitlines()
        if not lines:
            continue
        page = lines[0].strip()
        if page not in pages_to_do:
            continue
        nums = []
        for line in lines[1:]:
            if line.startswith('\t') and ':' in line:
                # format: \t<lineno>: <text>
                num_str = line.lstrip('\t').split(':', 1)[0].strip()
                try:
                    num = int(num_str)
                except ValueError:
                    continue
                nums.append(num)
        if nums:
            linenos_map[page] = nums

    # Process each page using cached text
    for page_title in pages_to_do:
        cache_path = f"{CACHE_DIR}/{page_title.replace('/', '_')}.txt"
        try:
            with open(cache_path, 'r', encoding='utf-8') as f:
                text = f.read()
        except FileNotFoundError:
            print(f"Cache miss for {page_title}, fetching from wiki...")
            page = Page(site, page_title)
            try:
                text = page.text
            except wikiex.Error as e:
                print(f"Error fetching {page_title}: {e}")
                continue
            if not text:
                continue
            # Also write to cache for future use
            try:
                with open(cache_path, 'w', encoding='utf-8') as f:
                    f.write(text)
            except OSError as e:
                print(f"WARNING: cannot cache {page_title}: {e}")
                pass

        if page_title not in linenos_map:
            print(f"No line numbers for {page_title}, skipping.")
            continue

        lines = text.splitlines()
        modified = False
        target_linenos = linenos_map[page_title]

        print(f"{page_title}:", end="")
        for ln in target_linenos:
            idx = ln - 1
            if 0 <= idx < len(lines):
                orig = lines[idx]
                new_line = orig.replace('|pos=', '|ng=', 1)
                if new_line != orig:
                    lines[idx] = new_line
                    modified = True
                    print(f"\n\t{ln}: {new_line}", end="")

        if modified:
            # Save is still commented out for testing
            # page = Page(site, page_title)
            # page.text = '\n'.join(lines)
            # page.save(summary=EDIT_SUMMARY, minor=True, botflag=True, tags=['pywikibot'])
            print("\nSaved in test mode\n")
        else:
            print(" not saved\n")


if __name__ == '__main__':
    if not exists(PAGES_FILEPATH):
        fetch_contribs()
    else:
        correct_contribs()