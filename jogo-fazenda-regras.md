# Jogo de Fazenda em Cartas (Godot) - Documento de Regras

Engine: Godot 4.x (GDScript)
Inspiração: Card Survival (e Stacklands)

## Conceito
Nome (candidatos, não decidido): Card Lands, Fields of Cards.
Jogo de fazenda baseado em cartas de ação, itens e locais. O jogador combina cartas para transformar o estado da fazenda. Pressão vem de contas a pagar e gerenciamento de tempo e recursos, sem fome.

## Mecânica central: combinar cartas
Arrastar uma carta sobre outra executa uma receita (A + B = C).

Exemplos de cadeia:
- Enxada + Solo = Terra arada
- Semente + Terra arada = Terra semeada
- Terra semeada + tempo = Broto, depois Pronto para colher
- Colher = item de colheita (vendável)
- Floresta: área onde se executa a ação de cortar madeira (ferramenta + árvore = madeira)

## Tempo
- Em vez de AP por dia, cada ação gasta **minutos**.
- Relógio global (ideia: 06:00 a 22:00).
- Exemplos de custo (ajustar no balanceamento): arar 30 min, semear 15, regar 10, ir à cidade 1h.
- Crescimento das plantas e eventos ligados ao relógio.
- Dormir pula a noite.

## Contas a pagar (pressão principal)
- Contas com vencimento fixo: aluguel/financiamento semanal, luz, ração, juros.
- Cada conta é uma carta com prazo e valor.
- Pagar custa dinheiro e tempo (ir à cidade).
- Atraso gera multa/juros, não game over imediato.

## Economia e falência
- Itens são vendidos por dinheiro.
- Compras gastam dinheiro.
- O tempo está diretamente associado às dívidas.
- Game over: falência. Ideias em aberto (devaneio, não decidido):
  - Opção 1: perder tudo.
  - Opção 2: uma penalidade que faz o jogador voltar bem atrás.
  - Dívidas altas podem trazer a polícia, que prende o jogador, e as coisas estragam na fazenda.
- Fim do jogo (condição de vitória/objetivo final): fica para depois.

## Recipientes com volume
- O regador tem volume armazenado, medido em gramas, que vai sendo gasto a cada uso.

## Recursos
- Dinheiro, sementes, ferramentas (com desgaste e conserto).
- Escolhas: plantio barato de ciclo longo vs. caro que paga antes da conta vencer.

## Tipos de cartas e áreas
- Tipos: locais, ferramentas e itens.
- Mochila: serve para carregar itens (o que o jogador leva consigo). A capacidade também é medida em gramas.
- Armazenamento (storage): pode existir em locais e permite guardar itens. A capacidade é medida em gramas (cada item tem um peso).
- Locais: casa, fazenda, cidade, lojas, feira, floresta. Lojas e feira ficam dentro da cidade (chega-se na cidade e escolhe-se aonde ir).
- Lojas: ferragem (loja de ferramentas e materiais).
- Área da fazenda: a fazenda tem um valor numérico de área que limita a quantidade de coisas que cabem nela. A unidade é o metro quadrado (m²), usado como unidade de tile.
- Locais são cartas eternas que mudam o local do jogador. Cada local é uma área de cartas própria; o jogador leva itens de um local a outro pela mochila.
- Acesso aos locais (a definir): a partir de uma carta mapa (para não poluir as cartas disponíveis), ou numa lista à direita da lista de cartas, que pode ser escondida.

## Locais dentro da fazenda
- Casa.
- Sheds (casebres), nomeados.
- Galinheiro, nomeado.
- Celeiro, nomeado.
- Roças (farmlands), nomeadas.
- É permitido construir uma roça. No começo do jogo já existe uma criada.
- Uma roça é um local construído, como o shed, e dá um multiplicador (de performance, como as outras construções).
- Os m² da fazenda são um limite global, somando todos os locais.

## Recursos nos locais
Dentro dos locais há recursos finitos e infinitos.
- Infinitos: terra bruta, árvores, água de riacho.
- Terra bruta não ocupa espaço: serve para arrastar a enxada nela e gerar cartas de terra arada. A terra arada sim ocupa espaço (m² da fazenda) e possui um contador de m².
- Finitos: a definir.

## Ações com tempo variável
- O resultado de uma ação depende do tempo gasto (ex.: m² de terra arada gerados ao arar).
- Ferramentas têm qualidade: quanto melhor a qualidade, mais se produz no mesmo tempo.
- Ao realizar a ação, aparece um diálogo com um slider para escolher o tempo gasto.

## Ferramentas válidas
- Enxada: arar terra.
- Regador: regar plantas.
- Machado: cortar madeira.
- Serrote: cortar madeira.
- Martelo: construir com madeira.
- Em avaliação: ancinho e foice, para limpeza do terreno e remoção de ervas daninhas, talvez com algum nível de colheita.

## Ferramentas: durabilidade e manutenção
- Cartas de ferramenta possuem durabilidade.
- Tiers de ferramenta (ideia, em vez de tiers por minerais): barata, normal, de qualidade e premium.
- Fio: característica da ferramenta que representa a capacidade de cortar. Na manutenção, é possível afiar a ferramenta. Baixa durabilidade aumenta a velocidade com que se perde fio.
- Será possível combinar ferramentas com torneira, palha de aço e óleo para limpeza, diminuindo a degradação.

## Status das cartas
- Cartas podem ter status, diferentes de buffs/debuffs do jogador: sujo, molhado, enferrujado, entre outros.
- Exemplo ligado à manutenção: palha de aço e óleo removem ou previnem ferrugem.

## Modificadores (buffs e debuffs)
- O jogo usa modificadores baseados em buffs e debuffs.
- Alimentos geram buffs.
- Mochila pesada gera um debuff.

## Interface das cartas
- Permitir a reordenação de cartas no local, no storage e na mochila.
- A reordenação deve ser preservada.
- Área de stage: cartas novas (colheita, entregas) chegam nela, e o jogador é obrigado a escolher onde elas vão ficar (a confirmar).
  - A stage é o "chão" do local: as cartas ficam lá, e se o jogador voltar no mesmo dia, continuam lá.
  - O chão é livre (sem limite de espaço), mas as coisas somem no final do dia.
  - Os itens que somem vão para uma caixa de achados e perdidos, com uma mensagem no correio avisando.
  - Os itens ficam no achados e perdidos por 7 dias.
  - O achados e perdidos fica na vila.
- Se já existir uma carta igual no destino, a nova apenas soma nas que existem, com algum sinal visual.

## Estrutura técnica (Godot)
- `CardData` (Resource): nome, ícone, tipo (ferramenta, terreno, semente, item), durabilidade, custo em minutos.
- `Recipe` (Resource): carta A + carta B = resultado, custo em minutos, se a ferramenta é consumida ou só perde durabilidade.
- Autoload `Clock`: tempo em minutos + sinal `time_changed`; plantas, contas e eventos se inscrevem nele.
- Arrastar e soltar checa se existe receita.
- Boas práticas anti-stuttering: object pooling, carregamento assíncrono, cachear referências, evitar alocações em runtime.

## Arquitetura de testes e simulação
- Motor de regras separado da UI (classes `RefCounted`, sem Nodes), com API de comandos (`apply_recipe`, `advance_time`, `get_state`).
- RNG com seed para simulações reproduzíveis.
- Testes unitários com GUT ou gdUnit4.
- Simulação de longa duração em modo headless com bots (barato, prioriza contas, aleatório) e métricas (dias até falir, saldo médio, taxa de atraso).

## Animais de criação
- Precisam de comida, limpeza e felicidade.
- Comida: resolve-se dando comida.
- Felicidade: resolve-se brincando, criando formas de eles se entreterem.
- Limpeza: limpando os animais e o celeiro.
- Podem morrer se ficarem muito tempo sem comida ou água, ou se ficarem muito deprimidos.
- Têm produção, baseada em quão bem estão.
- Tipos de alimentação: orgânico, ração de manutenção, ração de postura, ração de engorda e ração de crescimento.
- Destino dos animais: podem ser vendidos, mantidos na fazenda ou ir para o corte.

## Ideias futuras
- Mais de uma cidade: uma vila pequena próxima da fazenda, com lojas limitadas em opções e qualidade; uma cidade maior, com mais variedade, porém mais longe.
  - A cidade maior pode ser liberada por veículo. Inicialmente, ir a pé demora muito e é inviável.
  - Opção de ter onde dormir na vila. Custa dinheiro.
  - O veículo também libera outras fazendas de outros produtores, para comprar animais diferenciados, sementes de qualidade e afins.
  - Veículos possíveis: bicicleta, motocicleta, camionete e caminhão.
  - O veículo é um local: tem destinos diferentes, armazenamento próprio e um multiplicador de viagem.
  - O armazenamento do veículo pode servir como depósito extra, como no mundo real. O incômodo aparece na hora de usar o veículo: o jogador precisa descarregar e carregar.
  - O veículo necessita de combustível. A bicicleta não usa combustível.
  - Combustível único, chamado "combustível" (substitui gasolina e diesel). Vale também para as máquinas.
- Construções da fazenda: armários, barris, galinheiro, celeiro, poço e outras coisas de fazenda. Cada construção pode ser feita por um profissional contratado ou pelo próprio jogador.
  - O profissional faz com qualidade mediana.
  - O jogador começa fazendo com qualidade ruim, mas com o tempo aprimora e pode passar a fazer melhor que o profissional.
  - Uma construção tem a mesma área dentro e fora (um shed de 6 m² tem 6 m² dentro e fora). A qualidade da construção afeta apenas o multiplicador de performance.
  - Exemplo: um armário consome 1 m² e comporta 100 kg. Armários melhores aguentam mais.
  - Construções têm durabilidade e precisam de reparos.
  - Construções danificadas reduzem a eficiência dos trabalhos feitos dentro delas.
  - Ideia: cada construção tem um multiplicador de eficiência. Construções melhores começam com um multiplicador melhor, e os danos são debuffs que reduzem esse multiplicador.
  - O multiplicador vale para qualquer trabalho feito dentro da construção.
  - Não haverá muitos níveis de construção.
  - Construções são locais, e dentro delas ficam maquinários (a confirmar).
- Construção de casebres (sheds).
  - Permitem colocar coisas dentro, como armários para guardar as ferramentas ou barris de conserva.
  - Conservas são uma forma de criar itens artesanais, para incrementar o valor de venda. Perecíveis não são uma preocupação por enquanto.
  - Guardar ferramentas sujas ou molhadas diminui a durabilidade delas.
- Mochilas com maior capacidade de carga.
- Sistema de correspondência (apenas recebida), que funciona como as notificações do jogo: promoções, contas, novos itens.
  - A correspondência sempre chega no início do dia.
  - A caixa de correio é um storage com cartas que são literalmente cartas (correspondência). Ao clicar, podem ser lidas. Ler não gasta tempo.
  - O correio serve para avisos e dicas do jogo.
  - O correio também pode trazer envios, que viram cartas na mochila (a confirmar). As contas entram nessa.
  - Promoções duram por intervalos de dias.
- Camada de skills (em avaliação): ideia original era informar a porcentagem de chance de algo funcionar. Skills também podem influenciar a quantidade de recurso gerado e a qualidade do resultado. Com o slider de tempo, já é possível gastar mais tempo para obter mais recursos ou qualidade.
  - Progressão linear no sentido de não haver variantes nem caminhos: à medida que se joga, o jogador ganha pontos de skill, e aquela atividade fica mais produtiva.
  - Ganho inversamente proporcional: quanto mais skill, mais difícil ganhar skill. A curva que representa isso é uma exponencial saturante, 1 − e^(−x).
- Pets de trabalho:
  - Cachorros espantam animais selvagens.
  - Gatos espantam ratos.
- Pragas e predadores:
  - Animais selvagens (raposas) comem ovos e galinhas.
  - Ratos estragam plantações.
- Construção de um açude e criação de peixes.
- Contratar ajudantes que realizam determinadas tarefas no lugar do jogador. Ajudantes melhores custam mais e produzem mais.
- Compra de maquinário, como evolução das ferramentas:
  - Regadores automatizados.
  - Veículos para carga de maiores volumes.
  - Alimentador automático de animais.
  - Máquinas de arado.
- Máquinas consomem combustível como energia.
- Lista de maquinários possíveis (sugestões, todas anotadas):
  - Lavoura: trator (ara mais m² por minuto), irrigação por aspersor ou gotejamento (regador automático, pode ligar ao poço), colheitadeira (colhe muitos m² no mesmo tempo).
  - Madeira e construção: motosserra (corta madeira mais rápido que machado e serrote), serra circular de bancada dentro de um shed (tronco em tábua).
  - Oficina e manutenção: esmeril (afia rápido, ligado ao fio), lavadora de alta pressão (limpa ferramentas sujas).
  - Animais: bebedouro automático (ao lado do alimentador automático), chocadeira (para o galinheiro).
  - Artesanal e venda: moinho (grão em farinha), prensa (itens de maior valor, como as conservas).
  - Infraestrutura: bomba d'água (liga o poço à irrigação), gerador (alimenta as máquinas de um shed com combustível).
  - Prioridade sugerida para o começo: motosserra, esmeril, bomba d'água com irrigação e trator.

## Balanceamento
- Escala de tempo: seguir o fluxo dos jogos de fazenda em geral, onde plantações são rápidas (ex.: cenoura em poucos dias) e animais seguem um ritmo mais realista (um ovo por dia). Motivo: manter a ideia de o personagem viver o dia, que é interessante. Ainda não definitivo.
- Balanceamento inicial baseado em métricas reais de peso, capacidade e energia, depois ajustado para aumentar a diversão. Os tempos de cultivo não seguem o mundo real (um ciclo de meses é comprimido).

## Venda
- Feira: é possível alugar um espaço e colocar itens à venda. Vender na feira gera mais lucro do que vender em lote, usando um multiplicador.
- Caixa de venda na própria fazenda: permite colocar cartas para serem vendidas, com um multiplicador menor.

## Progressão e desbloqueio
- Fluxo do jogo: liberar aos poucos lugares, itens à compra e ferramentas, conforme coisas vão ocorrendo e correspondências (e-mails) vão chegando.
- Objetivo: dar tempo ao jogador de se acostumar de antemão com as mecânicas.

## Foco
Muita coisa vai entrar como regras e cartas. A prioridade é a mecânica base: relógio em minutos, combinar cartas (receitas), contas a pagar, mochila e armazenamento em gramas, locais. O resto vem depois.

## Decisões em aberto
- Gatilho da falência e consequência: perder tudo ou penalidade de retorno (ver "Economia e falência")
- Acesso aos locais: carta mapa ou lista à direita escondível
- Limite de peso (em gramas) da mochila e do armazenamento de cada local
- Duração do dia e quantidade de minutos disponíveis
- Valores das contas e frequência
- Objetivo final: fica para depois (a falência é o game over)
- Animais, clima, estações

## Requisitos de fluidez e conforto
- O jogo precisa ser perfeitamente fluido a 180 Hz. O desenvolvedor tem motion sickness (já teve náusea só com um retângulo desenhado à mão no Godot, causa desconhecida).
- Regras do projeto: animações com `Tween` (baseadas em tempo, não em frame), V-Sync ligado e sem limite artificial de FPS, sem alocações em runtime, sem buscas de nós por frame, shaders simples.
- Câmera parada: sem tremor de tela, sem zoom ou rolagem automática, animações curtas e suaves.
- Opção de "movimento reduzido" que troca as animações por trocas instantâneas.
- Suspeitas a verificar na máquina: taxa do monitor (60 vs 180 Hz), V-Sync, movimento em `_physics_process` (60 Hz) com a tela a 180 Hz (jitter), bordas cintilando por posição fracionada, gráfica integrada em vez da dedicada.
- Conforto é validado pelo desenvolvedor na própria máquina, com o gráfico de tempo de frame (Debugger → Profiler).

## Próximo passo sugerido
Antes da demo: uma cena de teste de conforto minúscula (uma carta que se move e arrasta), com opções que se alternam na hora (V-Sync, interpolação, movimento reduzido), para validar na máquina do desenvolvedor.

Depois, o protótipo: relógio, receitas arar/semear/colher, venda da colheita e uma conta semanal.
