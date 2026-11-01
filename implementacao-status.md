# Fields of Cards - Status da implementação

Registro do que está implementado, do que ficou de fora e das decisões que tomei sem você para o jogo andar. **Tudo o que está em "Valores provisórios" e "Perguntas" precisa da sua revisão.** Os testes (`tests/run_all.sh`) passam em todas as features; a fluidez a 180 Hz e a aparência da tela não foram validadas (só você pode).

## Como rodar
- Todos os testes: `tests/run_all.sh` (roda `godot --headless --import` antes e cada `tests/check_*.gd`).
- Simulação com bots: `godot --headless --path . -s tools/simulate.gd -- days=60 seed=1 diligence=0.7`.
- Em um clone novo, rode `godot --headless --path . --import` uma vez antes dos testes (cache de classes).

## Features implementadas (com teste)
| Feature | Teste |
|---|---|
| 1 Receitas por arrastar, 2 Relógio e dia, 3 Cartas/ordem, 4 Locais, 5 Peso, 6 Área da fazenda | `check_recipes`, `check_clock`, `check_cards`, `check_locations`, `check_weight`, `check_farm_area` |
| 7 Economia, 8 Dívida e falência, 9 Estado/simulação, 10 Conforto | `check_economy`, `check_debt`, `check_simulation`, `check_comfort` |
| 11 Tempo variável, 12 Multiplicadores, 13 Desgaste, 14 Status, 15 Buffs | `check_variable_time`, `check_multipliers`, `check_wear`, `check_status`, `check_buffs` |
| 16 Chão e achados e perdidos, 17 Correio, 18 Progressão, 19 Estado inicial | `check_ground`, `check_mail`, `check_progression`, `check_initial` |
| 20 Áreas, 21 Menu/vídeo, 22 Estado e save | `check_areas`, `check_video_settings`, `check_game_state` |
| 23 Animais, 24 Construções, 25 Skills, 26 Mapa e veículos, 27 Pets/pragas/ajudantes, 28 Maquinário, 29 Ervas e açude | `check_animals`, `check_buildings`, `check_skills`, `check_vehicles`, `check_pests`, `check_machines`, `check_extras` |

## O que ficou de fora ou parcial
- **US-8.3 / F2** (consequência da falência): a falência só encerra o jogo. O gatilho é um limite de dívida vencida (`bankruptcy_debt_limit`), desligado por padrão no motor e em 150 na simulação.
- **US-8.4 / F3** (polícia) e **US-8.5 / D8** (vitória): [ideia] e adiada, não feitos.
- **US-13.6 / G6** (tiers de ferramenta): só existe o campo `quality`; não há tiers prontos.
- **US-12.5 / E2** (aluguel da banca na feira): a banca existe com multiplicador 1,3, sem aluguel nem limite de cartas.
- **US-25.3 / K4** (porcentagem de chance): mostra só o nível de skill.
- **US-1.7 / P5** (reabastecer o regador): não há como encher o regador; na simulação isso é suposto (`refill_water`).
- **US-26.2**: o preço da pousada (30) é um palpite. **US-23.3**: a água dos animais não existe, só comida.
- **AR9/AR10** (abrir o veículo da mão): o depósito do veículo só abre com a carta no local ou no chão.
- Interface: segue o layout do `mockup/tela-jogo.html` (Local em cima, Mochila embaixo, Mão à esquerda, contexto à direita, Chão no centro, dock de ícones). Ao arrastar, uma cópia da carta acompanha o mouse; soltar sobre outra carta mostra contorno amarelo se houver receita. As observações do desenvolvedor estão em `observacoes.md`. Os diálogos e a tela não foram vistos por mim em execução.

## Valores provisórios (para balancear, Z7)
Todos estão em dados ou em constantes comentadas.
- Tempos: arar 30 min/4 m², semear 10, regar 10, colher 10, cortar 30, construir 60; viagens fazenda–floresta 30, fazenda–cidade 60, floresta–cidade 90, vila 15, cidade grande 180 a 270.
- Pesos e limites: mochila 20 kg, baú 50 kg, armário 100 kg; mochila pesada acima de 80% do limite.
- Dinheiro inicial 100; preços da ferragem (enxada 50 etc.); venda: colheita 10, caixa 0,8x, banca da feira 1,3x.
- Multa de atraso 10% uma vez; sem juros por tempo.
- Fazenda com 100 m². Roça inicial com durabilidade 40 (danificada).
- Cansado: 1,25x tempo e 0,9x rendimento; sobrecarregado: 1,25x tempo; energizado: 0,9x tempo e 1,1x rendimento (`data/buffs.json`).
- Skill: nível = 1 − e^(−pontos/50), bônus máximo 2x; qualidade do jogador na construção de 0,6 a 1,4.
- Desgaste: durabilidade 100 a 0, com 0 a ação leva 4x; fio e status (enferrujada 1,5x, sujo 1,25x, oleada 0,5x).
- Animais, pragas (25% por noite), ajudantes (10 a 30 de salário), máquinas e veículos: ver `data/cards/*.tres`.
- O crescimento é por dia regado: semeada, broto, pronta (1 dia cada). A erva no local congela o plantio.
- Progressão: floresta e vila no dia 2, cidade no dia 3, ferramentas no dia 5 (`data/mail.json`, `data/progression.json`).

## Decisões que tomei (confirme ou mude)
1. **Dinheiro** é uma carta `dinheiro` cuja quantidade é o valor, e paga-se da mão e depois da mochila.
2. **Onde caem as coisas**: cartas móveis novas vão para o chão (H1); a terra e as construções ficam no local; dinheiro, compras, anexos de carta e itens do achados e perdidos vão para a mão.
3. **Iguais para somar (C4)**: mesmo `id` e mesmos dados extras (estado, propriedades, buffs). Um estágio de plantio diferente é outra carta.
4. **Peso** é unitário × quantidade, e o storage conta o conteúdo.
5. **Tempo variável**: unidades inteiras, e o consumo, o resultado e o desgaste crescem juntos.
6. **Meia-noite** longe de casa: o jogador dorme onde está. Dormir é possível a qualquer hora; passar das 22:00 acordado dá o cansado.
7. **Machado e serrote** têm a mesma receita (O que fazem de diferente é uma pergunta aberta).
8. **Achados e perdidos** ficou na **vila** (Q1), e a cidade grande exige veículo (Q3); a "cidade" original continua sendo a cidade com ferragem e feira.
9. **Pragas** só rodam em jogo com estado inicial (`pests_enabled`), para os testes de outras regras não dependerem do sorteio.
10. **AR4 mudou**: o storage aberto aparece na área da direita e o local continua aberto (antes o storage tomava o lugar do local).
11. O estado ganhou versões (hoje 3); saves antigos (v1 e v2) ainda carregam.

## Perguntas ao desenvolvedor (das "Estórias" com Depende)
- Quanto de água cada m² precisa e como o regador reabastece (US-1.7, 5.4)? Qual loja vende sementes além do correio?
- Qual o gatilho e a consequência da falência (F2)? Juros por tempo ou só vencimentos (D6)? Valores e frequência das contas?
- Efeito do cansado e da mochila pesada; limites reais de peso; quantos itens cabem na mão?
- Como consertar enxada enferrujada, regador furado e roça danificada? Hoje: palha de aço remove ferrugem, a roça se conserta com martelo e madeira, o regador furado não tem conserto.
- Aluguel da banca na feira (por dia? quantas cartas?) e se a caixa de venda paga mais ou menos que o lote.
- Como fechar o veículo/abrir o veículo da mão? A mochila grande substitui ou convive com a comum (hoje vale a maior)?
- O que mudar depois que o bot da simulação (que não limpa erva nem se protege de pragas) faliu no dia 40: as pragas e ervas estão fortes demais ou o bot é fraco?
