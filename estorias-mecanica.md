# Fields of Cards - Estórias da mecânica

Quebra das features de `features-mecanica.md` em estórias pequenas. Cada feature é um épico, e cada estória cita as regras de `regras-mecanica.md` pelos códigos.

Como ler:
- Formato: **Como** [quem], **quero** [o quê], **para** [por quê]. Em seguida vêm o **Aceite** (como saber que está pronta) e as **Regras** (códigos).
- **Depende** marca uma decisão ainda em aberto (ver "Em aberto" na mecânica). A estória pode começar, mas a parte afetada espera a decisão.
- Etiquetas: **[base]** se implementa primeiro, **[depois]** vem em seguida, **[ideia]** ainda não está decidida.
- Os suplementos ficam fora deste arquivo.

---

## 20. Áreas e movimentação [base] - primeiro momento

**US-20.1** Como jogador, quero ter cinco áreas de cartas (mão, mochila, storage, local e stage), para organizar o que tenho.
Aceite: as cinco áreas existem, e cada uma guarda cartas.
Regras: AR1

**US-20.2** Como jogador, quero ver só as áreas que abri, para a tela não ficar poluída.
Aceite: as áreas não precisam estar todas visíveis ao mesmo tempo.
Regras: AR2

**US-20.3** Como jogador, quero abrir a mochila selecionando a carta dela, para ver o que carrego.
Aceite: a carta da mochila fica na área da mão, e ao selecioná-la a mochila abre embaixo.
Regras: AR3

**US-20.4** Como jogador, quero abrir um storage selecionando a carta dele, para ver o que guardei.
Aceite: ao selecionar a carta de um storage, ele abre em cima, no lugar do local.
Regras: AR4
Depende: como fechar um storage aberto e voltar ao local.

**US-20.5** Como jogador, quero o chão sempre disponível, para largar e pegar cartas a qualquer momento.
Aceite: o chão aparece em qualquer visão.
Regras: AR5

**US-20.6** Como jogador, quero mover cartas móveis entre as áreas abertas, para organizar o que carrego, guardo e deixo no chão.
Aceite: arrastar uma carta móvel de uma área aberta para outra a move; uma carta inerente ao local não se move.
Regras: AR6, C7, C8

**US-20.7** Como desenvolvedor, quero que as cartas tenham propriedades que se combinam (local, ferramenta, acumulável, móvel, inerente ao local, veículo) e possam ter buffs e debuffs, para o núcleo suportar sistemas novos sem reescrever.
Aceite: acrescentar uma propriedade ou um buff a uma carta é uma mudança em dados, sem alterar o mecanismo das áreas.
Regras: C1, C9, Z8

**US-20.8** Como jogador, quero que um veículo seja um local dentro de outro local.
Aceite: um veículo é um local que tem uma localização dentro de outro local.
Regras: L8

**US-20.9** Como jogador, quero fechar a mochila clicando nela, para voltar à visão anterior.
Aceite: clicar na mochila aberta a fecha.
Regras: AR8

**US-20.10** Como jogador, quero uma área da mão, talvez na lateral, com um ou dois itens que estou segurando e a carta da mochila, para ter à mão o que uso.
Aceite: a área da mão mostra os itens segurados e a carta da mochila.
Regras: AR7
Depende: quantos itens cabem na mão, para que servem e se a lateral é a posição final.

**US-20.11** Como jogador, quero deixar a carta do veículo na área da mão, para acessá-lo rápido.
Aceite: a carta de um veículo pode ser colocada na área da mão e fica lá até ser movida.
Regras: AR9, L8
Depende: se a carta do veículo conta entre os itens segurados e como se abre ou fecha o veículo.

---

## 1. Receitas por arrastar [base]

**US-1.1** Como jogador, quero arrastar uma carta sobre outra para executar uma receita.
Aceite: se existe receita para o par, ela é executada; se não existe, as cartas não são alteradas.
Regras: C2

**US-1.2** Como jogador, quero que cada receita gaste os minutos definidos, para o tempo ter custo.
Aceite: ao executar a receita, o relógio avança o custo dela.
Regras: C3, T1

**US-1.3** Como jogador, quero que a ferramenta da receita seja consumida ou perca durabilidade, conforme a receita.
Aceite: a receita define qual dos dois acontece, e o resultado aparece na ferramenta.
Regras: C3

**US-1.4** Como desenvolvedor, quero declarar cartas e receitas como dados, para criar conteúdo sem mexer no código.
Aceite: acrescentar uma receita ou carta nova não exige alterar código.
Regras: C6

**US-1.5** Como jogador, quero arar a terra com a enxada, para ter terra arada.
Aceite: enxada + terra bruta gera uma carta de terra arada.
Regras: R1

**US-1.6** Como jogador, quero semear a terra arada, para plantar.
Aceite: semente + terra arada gera terra semeada.
Regras: R2

**US-1.7** Como jogador, quero regar as plantas com o regador.
Aceite: usar o regador numa planta executa a rega e gasta do volume do regador.
Regras: R3, P5
Depende: quanto de água cada m² precisa.

**US-1.8** Como jogador, quero que a terra semeada cresça com o tempo, para colher depois.
Aceite: com o passar do relógio, a terra semeada vira broto e depois fica pronta para colher. No dia em que não houve rega, o crescimento da roça fica congelado.
Regras: R4, T3, R9
Depende: como estágios diferentes convivem num mesmo contador de terra arada.

**US-1.9** Como jogador, quero colher o que está pronto, para ter itens de colheita para vender.
Aceite: colher gera um item de colheita vendável.
Regras: R5

**US-1.10** Como jogador, quero cortar árvores na floresta, para ter madeira.
Aceite: machado ou serrote + árvore gera madeira.
Regras: R6
Depende: o que machado e serrote fazem de diferente.

**US-1.11** Como jogador, quero construir com o martelo e a madeira.
Aceite: martelo + madeira executa a construção.
Regras: R7

---

## 2. Relógio e dia [base]

**US-2.1** Como jogador, quero ver a hora do dia, para planejar minhas ações.
Aceite: o relógio global aparece na tela e mostra o horário atual.
Regras: T2

**US-2.2** Como jogador, quero que toda ação avance o relógio, para o tempo ser o meu recurso.
Aceite: qualquer ação (inclusive viajar) avança o relógio no custo definido, que pode ser zero.
Regras: T1

**US-2.3** Como jogador, quero que plantas e eventos evoluam conforme o relógio, para o mundo andar sem mim.
Aceite: ao avançar o relógio, tudo que tem tempo (crescimento, eventos) é atualizado.
Regras: T3

**US-2.4** Como jogador, quero dormir para pular a noite e acordar às 06:00.
Aceite: ao dormir, o relógio avança até as 06:00 do dia seguinte e o que depende do tempo é atualizado.
Regras: T4, T8

**US-2.5** Como desenvolvedor, quero que o ritmo de crescimento de plantas e animais seja um dado, para ajustar a escala de tempo.
Aceite: mudar o tempo de crescimento de uma planta ou animal não exige alterar código.
Regras: T5, C6

**US-2.6** Como jogador, quero que o dia termine à meia-noite, para ter um limite claro para as minhas ações.
Aceite: às 00:00 o dia termina de forma inevitável, o jogador dorme e o que depende do fim do dia acontece.
Regras: T7
Depende: onde o jogador dorme se a meia-noite o pegar longe de casa.

**US-2.7** Como jogador, quero acordar cansado se passei das 22:00 acordado, para o horário ter consequência.
Aceite: se o relógio passou das 22:00 antes de eu dormir, acordo às 06:00 com o debuff de performance "cansado"; se dormi antes, não.
Regras: T9
Depende: efeito do debuff "cansado".

---

## 3. Cartas, áreas e ordem [base]

**US-3.1** Como jogador, quero distinguir as propriedades de cada carta (local, ferramenta, acumulável, móvel, inerente ao local, veículo), para saber o que posso fazer com ela.
Aceite: cada carta mostra claramente as suas propriedades.
Regras: C1

**US-3.2** Como jogador, quero que cada local mostre a sua própria área de cartas.
Aceite: ao entrar num local, vejo só as cartas daquele local.
Regras: L2

**US-3.3** Como jogador, quero reordenar as cartas no local, no storage e na mochila, para me organizar.
Aceite: arrastar uma carta muda a sua posição na área.
Regras: C5

**US-3.4** Como jogador, quero que a ordem das minhas cartas seja preservada, para não ter que reorganizar.
Aceite: ao sair e voltar a uma área, e ao salvar e carregar, a ordem é a mesma.
Regras: C5, Z3

**US-3.5** Como jogador, quero que cartas iguais que chegam ao mesmo lugar se somem, com um sinal visual, para não poluir a mesa.
Aceite: ao chegar uma carta igual a uma existente, ela se soma, e um destaque estático indica a soma.
Regras: C4, W6
Depende: o que torna duas cartas "iguais".

---

## 4. Locais navegáveis [base]

**US-4.1** Como jogador, quero ir a outro local escolhendo a carta dele, para me deslocar.
Aceite: escolher uma carta de local muda onde estou, e a viagem gasta minutos.
Regras: L1, T1
Depende: como acessar os locais (carta mapa ou lista à direita).

**US-4.2** Como jogador, quero levar itens de um local a outro pela mochila.
Aceite: o que está na mochila continua comigo ao mudar de local, e o resto fica onde está.
Regras: L3

**US-4.3** Como jogador, quero ter os locais iniciais: fazenda (com a casa dentro), floresta e cidade.
Aceite: no começo do jogo esses locais existem e podem ser visitados.
Regras: L4

**US-4.4** Como jogador, quero escolher, dentro da cidade, entre as lojas e a feira.
Aceite: ao chegar na cidade, posso escolher aonde ir, sem nova viagem longa.
Regras: L4

**US-4.5** Como jogador, quero comprar ferramentas e materiais na ferragem.
Aceite: a ferragem é uma loja da cidade, e comprar gasta dinheiro.
Regras: L5, D2

**US-4.6** Como jogador, quero os locais da fazenda (casa, sheds, galinheiro, celeiro e roças), com nome nos construídos.
Aceite: cada um é um local próprio, e os construídos têm nome.
Regras: L6

---

## 5. Peso e capacidade [base]

**US-5.1** Como jogador, quero ver o peso de cada carta móvel, para decidir o que levar.
Aceite: toda carta móvel mostra o seu peso em gramas, exceto o dinheiro, e locais não têm peso.
Regras: P1

**US-5.2** Como jogador, quero que a mochila tenha limite de peso, para ter de escolher o que carregar.
Aceite: a mochila mostra o peso carregado e o limite.
Regras: P2
Depende: limites de peso; o que acontece ao atingir o limite e o efeito do debuff da mochila pesada.

**US-5.3** Como jogador, quero guardar itens em storages com limite de peso.
Aceite: um storage aceita itens até o seu limite e pode existir em um local.
Regras: P3
Depende: limites de peso.

**US-5.4** Como jogador, quero que o regador tenha um volume em gramas que se gasta a cada uso.
Aceite: cada rega reduz o volume do regador, e com o volume zerado ele não rega.
Regras: P5
Depende: quanto de água cada m² precisa e como o regador reabastece.

---

## 6. Área da fazenda [base]

**US-6.1** Como jogador, quero que a fazenda tenha um limite de m², para expandir ter um custo.
Aceite: o total de m² usados, somando todos os locais da fazenda, não passa do limite.
Regras: L7

**US-6.2** Como jogador, quero terra bruta infinita que não ocupa espaço, para sempre poder arar.
Aceite: a terra bruta não conta nos m² da fazenda e não se esgota.
Regras: N1, N2

**US-6.3** Como jogador, quero ver quantos m² tem cada carta de terra arada.
Aceite: a terra arada ocupa m² da fazenda e mostra um contador.
Regras: N3
Depende: como estágios diferentes convivem num mesmo contador.

**US-6.4** Como jogador, quero árvores e água de riacho infinitas, para só gastar tempo com elas.
Aceite: usar árvores e água de riacho não esgota o recurso.
Regras: N1

---

## 7. Economia [base]

**US-7.1** Como jogador, quero vender itens por dinheiro.
Aceite: colocar itens no container da fazenda vende em lote e converte os itens em dinheiro.
Regras: D1, E1

**US-7.2** Como jogador, quero comprar gastando dinheiro.
Aceite: uma compra desconta o valor do dinheiro e entrega o item.
Regras: D2

**US-7.3** Como jogador, quero receber contas como cartas com prazo e valor, para saber o que preciso pagar.
Aceite: uma conta é uma carta que mostra prazo e valor.
Regras: D3
Depende: valores e frequência das contas.

**US-7.4** Como jogador, quero pagar uma conta gastando dinheiro e o tempo de ir à cidade.
Aceite: pagar desconta o valor, e o deslocamento gasta minutos.
Regras: D4

**US-7.5** Como jogador, quero que a dívida gere multa, e não o fim imediato do jogo.
Aceite: uma dívida gera multa, e o jogo continua.
Regras: D5
Depende: valor da multa. Os malefícios da dívida ficam para depois.

**US-7.6** Como jogador, quero que o dinheiro seja uma carta de nota, sem peso, para guardá-lo e usá-lo como as outras cartas.
Aceite: o dinheiro aparece como carta em forma de nota e não conta no peso.
Regras: D9

---

## 8. Dívida e falência [base]

**US-8.1** Como jogador, quero que as dívidas evoluam com o tempo, para sentir a pressão do relógio.
Aceite: ao avançar o relógio, as dívidas são atualizadas.
Regras: D6
Depende: se são juros por tempo ou só vencimentos.

**US-8.2** Como jogador, quero que a falência encerre o jogo.
Aceite: ao cumprir a condição de falência, o jogo termina.
Regras: D7, F1
Depende: o gatilho da falência.

**US-8.3** Como jogador, quero uma consequência clara para a falência, para entender o que perdi.
Aceite: a falência aplica a consequência escolhida (perder tudo, ou uma penalidade que faz voltar bem atrás).
Regras: F2
Depende: escolher entre as duas opções.

**US-8.4** [ideia] Como jogador, quero que dívida alta traga a polícia, que me prende, e que as coisas da fazenda estraguem enquanto isso.
Aceite: acima de certa dívida, o jogador é preso e a fazenda segue sem ele.
Regras: F3
Depende: faixas de dívida.

**US-8.5** [adiada] Como jogador, quero um objetivo final, para saber quando venci.
Aceite: a condição de vitória está definida e testável.
Regras: D8
Depende: fim do jogo, que fica para depois.

---

## 9. Estado, testes e simulação [base]

**US-9.1** Como desenvolvedor, quero o motor de regras separado da interface, para testá-lo sem tela.
Aceite: o motor é feito de classes `RefCounted`, sem `Node`, cena ou UI.
Regras: Z1

**US-9.2** Como desenvolvedor, quero uma API de comandos, para o jogo e os testes usarem o mesmo código.
Aceite: existem comandos como `apply_recipe`, `advance_time` e `get_state`, e a interface só os chama.
Regras: Z2

**US-9.3** Como jogador, quero salvar e carregar o jogo, mantendo a ordem das minhas cartas.
Aceite: ao carregar, o estado e a ordem das cartas são os mesmos de quando salvei.
Regras: Z3

**US-9.4** Como desenvolvedor, quero um RNG com seed, para reproduzir simulações.
Aceite: a mesma seed e os mesmos comandos geram o mesmo resultado.
Regras: Z4

**US-9.5** Como desenvolvedor, quero testes unitários rodando pela linha de comando.
Aceite: os testes (GUT ou gdUnit4) rodam sem abrir o editor e falham quando uma regra quebra.
Regras: Z5

**US-9.6** Como desenvolvedor, quero simular muitos dias com bots, para medir o equilíbrio.
Aceite: uma simulação headless roda com bots e registra dias até falir, saldo médio e taxa de atraso.
Regras: Z6

**US-9.7** Como desenvolvedor, quero partir de métricas reais de peso, capacidade e energia, e ajustar depois para ficar divertido.
Aceite: os valores iniciais vêm de métricas reais, e ajustá-los é uma mudança em dados.
Regras: Z7, C6

---

## 10. Fluidez e conforto [base]

**US-10.1** Como jogador com motion sickness, quero o jogo fluido a 180 Hz, para jogar sem desconforto.
Aceite: o tempo de frame se mantém estável a 180 Hz na máquina do desenvolvedor.
Regras: W1, W7

**US-10.2** Como jogador, quero animações baseadas em tempo e V-Sync ligado, para não haver tremida.
Aceite: as animações usam `Tween`, o V-Sync está ligado e não há limite artificial de FPS.
Regras: W2

**US-10.3** Como desenvolvedor, quero evitar alocações em runtime e buscas de nós por frame, para não haver engasgos.
Aceite: o código por frame não aloca nem busca nós.
Regras: W3

**US-10.4** Como jogador, quero a câmera parada e animações curtas e suaves.
Aceite: não há tremor de tela, zoom nem rolagem automática.
Regras: W4

**US-10.5** Como jogador, quero uma opção de movimento reduzido, que troca as animações por trocas instantâneas.
Aceite: com a opção ligada, nenhuma animação de movimento acontece.
Regras: W5

**US-10.6** Como jogador, quero sinais visuais estáticos em vez de animações bruscas.
Aceite: destaques e avisos usam cor ou contorno, sem movimento brusco.
Regras: W6

---

## 11. Ações com tempo variável [depois]

**US-11.1** Como jogador, quero escolher quanto tempo gastar numa ação por um slider.
Aceite: ao agir, aparece um diálogo com um slider que define o tempo gasto.
Regras: V2

**US-11.2** Como jogador, quero que o resultado dependa do tempo que gastei, para ganhar mais dedicando mais tempo.
Aceite: gastar mais tempo gera mais resultado (por exemplo, mais m² de terra arada).
Regras: V1

---

## 12. Multiplicadores [depois]

**US-12.1** Como jogador, quero que uma ferramenta de melhor qualidade produza mais no mesmo tempo.
Aceite: a mesma ação, com o mesmo tempo, rende mais com a ferramenta de maior qualidade.
Regras: V3

**US-12.2** Como jogador, quero que a skill aumente a quantidade e a qualidade do que produzo.
Aceite: com mais skill na atividade, o resultado da ação é maior.
Regras: V4

**US-12.3** Como jogador, quero começar com uma roça e poder construir outras, que dão um multiplicador.
Aceite: o jogo começa com uma roça, e construir outra acrescenta um local com multiplicador.
Regras: R8

**US-12.4** Como jogador, quero que o multiplicador da construção valha para qualquer trabalho feito dentro dela.
Aceite: trabalhar dentro de uma construção aplica o multiplicador dela ao resultado.
Regras: V5

**US-12.5** Como jogador, quero vender na feira alugando um espaço, com multiplicador maior.
Aceite: na feira, itens postos à venda rendem mais que na venda em lote.
Regras: E2
Depende: se o aluguel é por dia e quantas cartas cabem.

**US-12.6** Como jogador, quero uma caixa de venda na fazenda, com multiplicador menor.
Aceite: cartas postas na caixa são vendidas com um multiplicador menor que o da feira.
Regras: E3
Depende: se paga mais ou menos que a venda em lote.

---

## 13. Desgaste e manutenção [depois]

**US-13.1** Como jogador, quero que as ferramentas percam durabilidade com o uso.
Aceite: usar uma ferramenta reduz a sua durabilidade, sem quebrar. Com durabilidade baixa, a mesma ação demora muito mais.
Regras: G1

**US-13.2** Como jogador, quero que ferramentas de corte tenham fio e que eu possa afiá-las.
Aceite: afiar uma ferramenta de corte restaura o fio.
Regras: G2

**US-13.3** Como jogador, quero que uma ferramenta de baixa durabilidade perca o fio mais rápido.
Aceite: a perda de fio por uso é maior quando a durabilidade é menor.
Regras: G3

**US-13.4** Como jogador, quero limpar ferramentas com torneira, palha de aço e óleo, para diminuir a degradação.
Aceite: combinar a ferramenta com esses itens limpa e reduz a degradação.
Regras: G4

**US-13.5** Como jogador, quero que guardar ferramenta suja ou molhada reduza a durabilidade, para eu ter de cuidar delas.
Aceite: guardar uma ferramenta com esses status reduz a durabilidade dela.
Regras: G5

**US-13.6** [ideia] Como jogador, quero ferramentas em tiers (barata, normal, de qualidade e premium), para escolher entre custo e desempenho.
Aceite: cada tier tem qualidade e custo próprios.
Regras: G6

---

## 14. Status de cartas [depois]

**US-14.1** Como jogador, quero ver os status de uma carta (sujo, molhado, enferrujado), para saber o estado dela.
Aceite: a carta mostra os seus status.
Regras: S1

**US-14.2** Como desenvolvedor, quero que as cartas possam ter buffs e debuffs além de status, para uma construção danificada ou outra carta ser afetada.
Aceite: uma carta pode receber um buff ou um debuff, além dos seus status.
Regras: S2, C9

---

## 15. Buffs e debuffs [depois]

**US-15.1** Como jogador, quero que a mochila pesada me dê um debuff, para o peso ter consequência.
Aceite: acima do peso definido, o jogador recebe o debuff.
Regras: P4
Depende: efeito do debuff e limites de peso.

**US-15.2** Como jogador, quero que alimentos me deem buffs.
Aceite: consumir um alimento aplica o buff dele.
Regras: S3

**US-15.3** Como jogador, quero que uma construção danificada reduza o seu multiplicador, para eu ter de repará-la.
Aceite: o dano gera um debuff que reduz o multiplicador da construção.
Regras: S4
Depende: durabilidade e reparo das construções (suplementos).

---

## 16. Chão e achados e perdidos [depois]

**US-16.1** Como jogador, quero que cartas novas cheguem ao chão do local e eu escolha onde ficam.
Aceite: colheitas e entregas aparecem no chão, e eu as movo para o destino que quiser.
Regras: H1

**US-16.2** Como jogador, quero um chão sem limite de espaço, em que as cartas ficam até o fim do dia.
Aceite: o chão aceita qualquer quantidade, e as cartas continuam lá se eu voltar no mesmo dia.
Regras: H2, H3

**US-16.3** Como jogador, quero que o que sobrar no chão vá para o achados e perdidos na virada de dia, com um aviso no correio.
Aceite: à meia-noite, as cartas do chão são movidas e chega uma mensagem avisando.
Regras: H4

**US-16.4** Como jogador, quero buscar no achados e perdidos da vila por até 7 dias.
Aceite: os itens ficam disponíveis por 7 dias e depois se perdem.
Regras: H5
Depende: a vila (suplementos).

---

## 17. Correio [depois]

**US-17.1** Como jogador, quero uma caixa de correio com cartas de correspondência que chegam no início do dia.
Aceite: toda manhã, quando o jogador acorda, chegam cartas novas à caixa, que é um storage.
Regras: M1, T6

**US-17.2** Como jogador, quero ler uma carta ao clicar nela, sem gastar tempo.
Aceite: clicar abre a carta, e ler custa 0 minutos por enquanto.
Regras: M2

**US-17.3** Como jogador, quero receber avisos e dicas do jogo pelo correio.
Aceite: avisos e dicas chegam como cartas de correspondência.
Regras: M3

**US-17.4** Como jogador, quero que uma carta de correspondência lida venha com um item anexo, como a carta da conta, para receber contas e outros itens.
Aceite: ao ler a carta, o item anexo aparece para mim.
Regras: M4
Depende: para onde vai o item anexo (mochila ou chão).

**US-17.5** Como jogador, quero promoções que durem por intervalos de dias.
Aceite: uma promoção vale por um intervalo de dias e depois acaba.
Regras: M5

---

## 18. Progressão e desbloqueio [depois]

**US-18.1** Como jogador, quero que lugares, itens à venda e ferramentas sejam liberados aos poucos, por eventos e correspondências.
Aceite: um evento ou uma carta do correio libera algo novo, que antes não estava disponível.
Regras: U1

**US-18.2** Como jogador, quero conhecer uma mecânica de cada vez, para me acostumar com cada uma.
Aceite: a ordem de liberação introduz as mecânicas de forma gradual.
Regras: U2

---

## 19. Estado inicial [base]

**US-19.1** Como jogador, quero começar com uma enxada enferrujada, um regador furado e um pouco de dinheiro.
Aceite: ao iniciar um jogo novo, tenho essas três coisas, e as ferramentas aparecem com os seus status.
Regras: I1
Depende: como consertar, e se os status e a manutenção entram na base.

**US-19.2** Como jogador, quero que a roça inicial esteja danificada, precisando de manutenção.
Aceite: no começo do jogo a roça existe e mostra que está danificada.
Regras: I2
Depende: manutenção e dano de construções (suplementos).

**US-19.3** Como jogador, quero uma mensagem de boas-vindas no correio com algumas sementes, para começar a plantar.
Aceite: a primeira carta da caixa de correio é de boas-vindas e vem com as sementes anexas.
Regras: I3, M4
