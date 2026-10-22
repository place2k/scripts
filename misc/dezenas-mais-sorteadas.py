#!/usr/bin/python

from sys import argv, stderr, exit
from time import perf_counter as timer
from random import shuffle
from locale import setlocale, LC_NUMERIC

loterias = {
  'megasena':  {'nome':'Mega-Sena', 'dezsort':6,  'dezmax':60, 'dataini': '11/03/1996', 'datafim': '20/12/2025'},
  'lotofacil': {'nome':'Lotofácil', 'dezsort':15, 'dezmax':25, 'dataini': '29/09/2003', 'datafim': '26/12/2025'},
  'lotomania': {'nome':'Lotomania', 'dezsort':20, 'dezmax':99, 'dataini': '02/10/1999', 'datafim': '26/12/2025'},
}

loteria_selecionada = argv[1]

if len(argv) == 1 or loteria_selecionada not in loterias:
  print(f'Uso: {argv[0]} [megasena|lotofacil|lotomania]', file=stderr)
  exit(1)

loteria = loterias[loteria_selecionada]
embaralhado = loteria_selecionada != 'lotofacil' and len(argv) == 3 and argv[2] == 'embaralhar-sugestão'

with open(f'loterias/{loteria_selecionada}', 'r') as lotofile:
  sorteios = [[int(dezena) for dezena in sorteio.split(' ')] for sorteio in lotofile.readlines()]
sorteios_totais = len(sorteios)
dezenas_totais = loteria['dezsort'] * sorteios_totais

contagem_de_dezenas = [{'dezena': d, 'valor': 0} for d in range(loteria['dezmax']+1)]
sorteios_contados = 0
dezenas_contadas = 0
max_ranking = 50 if loteria_selecionada != 'lotofacil' else 25

setlocale(LC_NUMERIC, 'pt_BR.UTF-8')
print(f'Computando as {max_ranking} dezenas mais sorteadas da {loteria['nome']}...')
print(f'(Analisando {dezenas_totais:n} dezenas de {sorteios_totais:n} sorteios entre {loteria['dataini']} e {loteria['datafim']}, '
      f'com {loteria['dezsort']}/{loteria['dezmax']} dezenas cada...)')

time_start = timer()

for sorteio in sorteios:
  pct_sorteios = sorteios_contados * 100 // sorteios_totais
  for dezena in sorteio:
    contagem_de_dezenas[dezena]['valor'] += 1
    dezenas_contadas += 1
  sorteios_contados += 1

time = int((timer() - time_start)*1000)

print(f'Análise concluída em {time} milissegundos ({sorteios_totais//time:n} sorteios ou {dezenas_totais//time:n} dezenas por milissegundo).')

ranking = sorted(contagem_de_dezenas, key=lambda par: par['valor'], reverse=True)[1:max_ranking]
cols = 5
rows = max_ranking//cols

def rank(): return f'({par['dezena']:02d}) [{contagem}/{contagem*100/sorteios_totais:>4.1f}%]'

print('\nResultado:', end='')
for row in range(rows):
  par = ranking[row]
  contagem = par['valor']
  n = row + rows
  print(f'\n  {row+1:>2}. {rank()}', end='  ')
  for col in range(1, cols):
    par = ranking[n-1]
    contagem = par['valor']
    print(f'{n+1:>2}. {rank()}', end='  ')
    n += rows

sugestão_sorteio = [par['dezena'] for par in ranking]
if embaralhado: shuffle(sugestão_sorteio)
sugestão_sorteio = sorted(sugestão_sorteio[0:loteria['dezsort']])

print('\n\nSugestão de aposta:')
for i, dezena in enumerate(sugestão_sorteio):
  print(f'({dezena:02d})', end=' ' if i < loteria['dezsort']-1 else '')
print()