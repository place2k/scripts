#!/bin/python
with open('/qb/at/addons/onetab/all.txt', 'r+') as onetab_log:
	onetab_links = onetab_log.readlines()

	onetab_unique_links = set()

	duplicates_count = 0

	for link in onetab_links:
		if link == '\n' or link not in onetab_unique_links:
			onetab_unique_links.add(link)
		else:
			print(link)
			duplicates_count += 1

	if duplicates_count == 0:
		print('No duplicates removed.')
	else:
		onetab_log.rewind()
		onetab_log.writelines(onetab_unique_links)
		print(f'{duplicates_count} duplicates removed.')
