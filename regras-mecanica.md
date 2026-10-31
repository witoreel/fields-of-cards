# Fields of Cards - Mecânica

Nome provisório. Jogo de fazenda em cartas (Godot 4.x, GDScript), inspirado em Card Survival e Stacklands.

Este arquivo reúne as regras que definem como o jogo funciona. O conteúdo que se acrescenta por cima dele (animais, construções, skills, veículos, maquinário e afins) está em `regras-suplementos.md`.

Como ler:
- Cada regra é curta e tem um código, para ser citada em testes e conversas. Os códigos são únicos nos dois arquivos.
- Etiquetas das seções: **[base]** é o que se implementa primeiro, **[depois]** está decidido mas vem em seguida, **[ideia]** é futuro ou ainda não decidido.
- **(aberto)** marca um detalhe sem decisão. Todos estão reunidos no fim do arquivo.
- Unidades: tempo em minutos, peso em gramas, área em m².

---

## Cartas [base]
- C1. Há três tipos de carta: local, ferramenta e item.
- C2. Arrastar uma carta sobre outra executa uma receita (A + B = C), se existir.
- C3. Uma receita define: cartas de entrada, resultado, custo em minutos e se a ferramenta é consumida ou só perde durabilidade.
- C4. Cartas iguais que chegam ao mesmo destino se somam, com um sinal visual.
- C5. A ordem das cartas em cada área (local, storage, mochila) pode ser reordenada e é preservada.
- C6. Conteúdo novo (carta, receita) é dado, não código.

## Tempo [base]
- T1. Toda ação gasta minutos.
- T2. Existe um relógio global.
- T3. Crescimento e eventos seguem o relógio.
- T4. Dormir pula a noite.
- T5. Plantas crescem rápido, no estilo dos jogos de fazenda; animais seguem um ritmo mais realista (um ovo por dia). Ainda não definitivo.
- T6. A correspondência chega sempre no início do dia.

## Dinheiro e dívidas [base]
- D1. Itens são vendidos por dinheiro.
- D2. Compras gastam dinheiro.
- D3. Uma conta é uma carta com prazo e valor.
- D4. Pagar uma conta custa dinheiro e o tempo de ir à cidade.
- D5. Atraso gera multa e juros, sem game over imediato.
- D6. O tempo está diretamente associado às dívidas.
- D7. O game over é a falência.
- D8. A condição de vitória fica para depois.

## Peso e armazenamento [base]
- P1. Todo item tem peso em gramas.
- P2. A mochila carrega itens e tem limite de peso.
- P3. Um storage guarda itens, tem limite de peso e pode existir em locais.
- P4. Mochila pesada gera um debuff.
- P5. O regador tem volume em gramas, gasto a cada uso.

## Locais [base]
- L1. Locais são cartas eternas que mudam onde o jogador está.
- L2. Cada local tem a sua própria área de cartas.
- L3. Itens passam de um local a outro pela mochila.
- L4. Locais do jogo: casa, fazenda, floresta e cidade. Lojas e feira ficam dentro da cidade.
- L5. A ferragem é uma das lojas (ferramentas e materiais).
- L6. Dentro da fazenda ficam: casa, sheds, galinheiro, celeiro e roças (farmlands). Os construídos têm nome.
- L7. A fazenda tem área em m², um limite global somando todos os locais.

## Recursos nos locais [base]
- N1. Terra bruta, árvores e água de riacho são infinitas.
- N2. Terra bruta não ocupa espaço: serve de alvo para a enxada.
- N3. Terra arada ocupa m² da fazenda e tem um contador de m².

## Lavoura e madeira [base]
- R1. Enxada + terra bruta = terra arada.
- R2. Semente + terra arada = terra semeada.
- R3. O regador rega as plantas.
- R4. Terra semeada + tempo = broto, depois pronta para colher.
- R5. Colher gera um item de colheita vendável.
- R6. Machado ou serrote + árvore (na floresta) = madeira.
- R7. Martelo + madeira = construir.
- R8. Uma roça é um local construído que dá um multiplicador. O jogo começa com uma.

## Falência [base]
- F1. A falência encerra o jogo.
- F2. Opções em estudo (aberto): perder tudo, ou uma penalidade que faz o jogador voltar bem atrás.
- F3. Ideia: dívida alta traz a polícia, que prende o jogador, e as coisas estragam na fazenda.

## Ações com tempo variável [depois]
- V1. O resultado de uma ação depende do tempo gasto.
- V2. Ao agir, um diálogo com slider define o tempo gasto.
- V3. A qualidade da ferramenta aumenta o que se produz no mesmo tempo.
- V4. A skill aumenta a quantidade e a qualidade do resultado.
- V5. O multiplicador da construção vale para qualquer trabalho feito dentro dela.

## Ferramentas [depois]
- G1. Ferramentas têm durabilidade, que cai com o uso.
- G2. Ferramentas de corte têm fio. Afiar restaura o fio.
- G3. Baixa durabilidade faz o fio se perder mais rápido.
- G4. Torneira, palha de aço e óleo limpam a ferramenta e diminuem a degradação.
- G5. Guardar ferramenta suja ou molhada diminui a durabilidade.
- G6. Ideia: tiers barata, normal, de qualidade e premium, em vez de tiers por minério.

## Status e modificadores [depois]
- S1. Cartas têm status próprios: sujo, molhado, enferrujado, entre outros.
- S2. Status são diferentes dos buffs e debuffs do jogador.
- S3. Alimentos geram buffs.
- S4. Construção danificada gera debuff no seu multiplicador.

## Chão e achados e perdidos [depois]
- H1. Cartas novas (colheita, entregas) chegam ao chão do local (a stage), e o jogador escolhe onde ficam (a confirmar).
- H2. O chão não tem limite de espaço.
- H3. As cartas no chão continuam lá se o jogador voltar no mesmo dia.
- H4. No fim do dia, o que está no chão vai para o achados e perdidos, com uma mensagem no correio.
- H5. O achados e perdidos fica na vila (ver Q1 em `regras-suplementos.md`) e guarda os itens por 7 dias.

## Correio [depois]
- M1. A caixa de correio é um storage cujas cartas são cartas de correspondência.
- M2. Ao clicar, a carta é lida. Ler não gasta tempo.
- M3. O correio traz avisos e dicas do jogo.
- M4. O correio também traz envios, que viram cartas na mochila (a confirmar). As contas entram aqui.
- M5. Promoções duram por intervalos de dias.

## Venda [depois]
- E1. Venda em lote é a base.
- E2. Na feira, o jogador aluga um espaço e vende com multiplicador maior.
- E3. A caixa de venda na fazenda vende com multiplicador menor.

## Progressão [depois]
- U1. Lugares, itens à venda e ferramentas são liberados aos poucos, por eventos e correspondências.
- U2. O objetivo é dar tempo ao jogador de se acostumar com cada mecânica.

---

## Arquitetura e testes [base]
- Z1. O motor de regras é separado da interface: classes `RefCounted`, sem `Node`, cena ou UI.
- Z2. A API é de comandos (`apply_recipe`, `advance_time`, `get_state`). A interface só chama a API.
- Z3. A ordem das cartas faz parte do estado e do save.
- Z4. RNG com seed, para simulações reproduzíveis.
- Z5. Testes unitários com GUT ou gdUnit4.
- Z6. Simulação longa em modo headless com bots e métricas (dias até falir, saldo médio, taxa de atraso).
- Z7. Balanceamento inicial com métricas reais de peso, capacidade e energia, ajustado depois para ser divertido. Tempos de cultivo são comprimidos.

## Fluidez e conforto [base]
- W1. Fluido a 180 Hz. O desenvolvedor tem motion sickness.
- W2. Animações com `Tween` (baseadas em tempo), V-Sync ligado, sem limite artificial de FPS.
- W3. Sem alocações em runtime nem buscas de nós por frame.
- W4. Câmera parada: sem tremor, zoom ou rolagem automática. Animações curtas e suaves.
- W5. Opção de movimento reduzido, que troca animações por trocas instantâneas.
- W6. Sinais visuais estáticos em vez de animações bruscas.
- W7. O conforto é validado pelo desenvolvedor na própria máquina.

## Em aberto
- Nome do jogo (Fields of Cards ou Card Lands).
- Acesso aos locais: carta mapa ou lista à direita, escondível.
- Gatilho e consequência da falência (F2).
- Como o tempo se liga às dívidas (D6): juros por tempo ou só vencimentos.
- Duração do dia e horário do relógio (ideia: 06:00 a 22:00).
- Limites de peso da mochila e dos storages.
- Efeito do debuff da mochila pesada.
- Valores e frequência das contas.
- O que torna duas cartas "iguais" para somar (C4).
- Como estágios diferentes de plantio convivem num mesmo contador de terra arada.
- Peso por carta ou por unidade (sementes, dinheiro).
- Água do regador: quanto cada m² precisa e como reabastece.
- O que machado e serrote fazem de diferente.
- Se a caixa de venda paga mais ou menos que a venda em lote (E3).
- Se o aluguel do espaço na feira é por dia e quantas cartas cabem.
- Fim do jogo e condição de vitória (fica para depois).
- Clima, estações.
