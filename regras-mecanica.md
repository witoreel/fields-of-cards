# Fields of Cards - Mecânica

Nome provisório. Jogo de fazenda em cartas (Godot 4.x, GDScript), inspirado em Card Survival e Stacklands.

Este arquivo reúne as regras que definem como o jogo funciona. O conteúdo que se acrescenta por cima dele (animais, construções, skills, veículos, maquinário e afins) está em `regras-suplementos.md`.

Como ler:
- Cada regra é curta e tem um código, para ser citada em testes e conversas. Os códigos são únicos nos dois arquivos.
- Etiquetas das seções: **[base]** é o que se implementa primeiro, **[depois]** está decidido mas vem em seguida, **[ideia]** é futuro ou ainda não decidido.
- **(aberto)** marca um detalhe sem decisão. Todos estão reunidos no fim do arquivo.
- Unidades: tempo em minutos, peso em gramas, área em m².

---

## Áreas e movimentação [base] - primeiro momento
- AR1. As áreas de cartas são: mão, mochila, storage, local e stage (o chão).
- AR2. As áreas não precisam estar todas visíveis ao mesmo tempo.
- AR3. Selecionar a carta da mochila, que fica na área da mão, abre a mochila embaixo.
- AR4. Selecionar a carta de um storage abre o storage na área contextual (à direita), sem fechar o local. (Mudou do original, "em cima, no lugar do local", a pedido do desenvolvedor no layout da tela.)
- AR5. O chão está sempre disponível.
- AR6. Cartas móveis podem ser movidas entre as áreas abertas.
- AR7. A área da mão, talvez na lateral, guarda os itens que o jogador segura (um ou dois) e a carta da mochila.
- AR8. Clicar na mochila aberta a fecha.
- AR9. O veículo pode ficar como carta na área da mão, de acesso rápido.
- AR10. Ao abrir um storage ou um veículo, o ícone dele aberto vai para a área da mão. Ao fechar, a carta volta para o local.

## Cartas [base]
- C1. Uma carta pode ser: local, ferramenta, acumulável, móvel, inerente ao local (não móvel) ou veículo. Essas propriedades se combinam.
- C2. Arrastar uma carta sobre outra executa uma receita (A + B = C), se existir.
- C3. Uma receita define: cartas de entrada, resultado, custo em minutos e se a ferramenta é consumida ou só perde durabilidade.
- C4. Cartas acumuláveis iguais que chegam ao mesmo destino se somam, com um sinal visual.
- C5. A ordem das cartas em cada área (local, storage, mochila) pode ser reordenada e é preservada.
- C6. Conteúdo novo (carta, receita) é dado, não código.
- C7. Uma carta móvel pode ser carregada e movida entre áreas.
- C8. Uma carta inerente ao local não é móvel.
- C9. Cartas podem ter buffs e debuffs.

## Tempo [base]
- T1. Toda ação gasta minutos, ainda que o custo seja zero. Os valores são balanceados depois.
- T2. Existe um relógio global.
- T3. Crescimento e eventos seguem o relógio.
- T4. Dormir pula a noite: o relógio avança até as 06:00 do dia seguinte.
- T5. Plantas crescem rápido, no estilo dos jogos de fazenda; animais seguem um ritmo mais realista (um ovo por dia). Ainda não definitivo.
- T6. A correspondência chega sempre no início do dia, quando o jogador acorda (a confirmar).
- T7. O dia termina à meia-noite (00:00), de forma inevitável. É a virada de dia, e o que depende do fim do dia acontece nela.
- T8. O jogador acorda às 06:00.
- T9. Se o jogador passar das 22:00 acordado, acorda com o debuff de performance "cansado".
- T10. No primeiro momento não havia relógio. Ele entrou com a feature 2: o estado guarda os minutos desde o início (o jogo começa às 06:00 do dia 1) e as ações gastam tempo.

## Dinheiro e dívidas [base]
- D1. Itens são vendidos por dinheiro.
- D2. Compras gastam dinheiro.
- D3. Uma conta é uma carta com prazo e valor.
- D4. Pagar uma conta custa dinheiro e o tempo de ir à cidade.
- D5. Dívida gera multa. Atraso não causa game over imediato. Os malefícios da dívida ficam para depois.
- D6. O tempo está diretamente associado às dívidas.
- D7. O game over é a falência.
- D8. A condição de vitória fica para depois.
- D9. Dinheiro é uma carta, em forma de nota, e não tem peso.

## Peso e armazenamento [base]
- P1. Toda carta móvel (carregável) tem peso em gramas, exceto o dinheiro. Locais não têm peso.
- P2. A mochila carrega itens e tem limite de peso.
- P3. Um storage guarda itens, tem limite de peso e pode existir em locais.
- P4. Mochila pesada gera um debuff.
- P5. O regador tem volume em gramas, gasto a cada uso.

## Locais [base]
- L1. Locais são cartas eternas que mudam onde o jogador está.
- L2. Cada local tem a sua própria área de cartas.
- L3. Itens passam de um local a outro pela mochila.
- L4. Locais do jogo: fazenda (com a casa dentro), floresta e cidade. Lojas e feira ficam dentro da cidade.
- L5. A ferragem é uma das lojas (ferramentas e materiais).
- L6. Dentro da fazenda ficam: casa, açude, sheds, galinheiro, celeiro e roças (farmlands). Os construídos têm nome.
- L9. O açude é um local da fazenda, a 10 minutos a pé de qualquer outro local dela (ida e volta). Sua água enche o regador (provisório; ver P5).
- L7. A fazenda tem área em m², um limite global somando todos os locais.
- L8. Um veículo é um local que tem uma localização dentro de outro local.

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
- R9. O crescimento da roça fica congelado no dia em que não há rega.

## Falência [base]
- F1. A falência encerra o jogo.
- F2. Opções em estudo (aberto): perder tudo, ou uma penalidade que faz o jogador voltar bem atrás.
- F3. Ideia: dívida alta traz a polícia, que prende o jogador, e as coisas estragam na fazenda.

## Estado inicial [base]
- I1. O jogo começa com uma enxada enferrujada, um regador furado e vazio e um pouco de dinheiro. Não há torneira no início.
- I2. A roça inicial começa danificada, precisando de manutenção.
- I3. Uma mensagem de boas-vindas no correio traz algumas sementes como item anexo.

## Ações com tempo variável [depois]
- V1. O resultado de uma ação depende do tempo gasto.
- V2. Ao agir, um diálogo com slider define o tempo gasto.
- V3. A qualidade da ferramenta aumenta o que se produz no mesmo tempo.
- V4. A skill aumenta a quantidade e a qualidade do resultado.
- V5. O multiplicador da construção vale para qualquer trabalho feito dentro dela.

## Ferramentas [depois]
- G1. Ferramentas têm durabilidade, que cai com o uso. A ferramenta não quebra: quanto menor a durabilidade, mais tempo a mesma ação leva.
- G2. Ferramentas de corte têm fio. Afiar restaura o fio.
- G3. Baixa durabilidade faz o fio se perder mais rápido.
- G4. Torneira, palha de aço e óleo limpam a ferramenta e diminuem a degradação.
- G5. Guardar ferramenta suja ou molhada diminui a durabilidade.
- G6. Ideia: tiers barata, normal, de qualidade e premium, em vez de tiers por minério.

## Status e modificadores [depois]
- S1. Cartas têm status próprios: sujo, molhado, enferrujado, entre outros.
- S2. Além de status, as cartas podem ter buffs e debuffs (C9). A relação entre os dois é uma pendência futura.
- S3. Alimentos geram buffs.
- S4. Construção danificada gera debuff no seu multiplicador.

## Chão e achados e perdidos [depois]
- H1. Cartas novas (colheita, entregas) chegam ao chão do local (a stage), e o jogador escolhe onde ficam (a confirmar).
- H2. O chão não tem limite de espaço.
- H3. As cartas no chão continuam lá se o jogador voltar no mesmo dia.
- H4. Na virada de dia (T7), o que está no chão vai para o achados e perdidos, com uma mensagem no correio.
- H5. O achados e perdidos fica na vila (ver Q1 em `regras-suplementos.md`) e guarda os itens por 7 dias.

## Correio [depois]
- M1. A caixa de correio é um storage cujas cartas são cartas de correspondência.
- M2. Ao clicar, a carta é lida. Ler custa 0 minutos por enquanto.
- M3. O correio traz avisos e dicas do jogo.
- M4. Uma carta de correspondência lida vem com um item anexo, como a carta da conta ou as sementes da mensagem de boas-vindas.
- M5. Promoções duram por intervalos de dias.

## Venda [depois]
- E1. A venda em lote é feita num container na fazenda.
- E2. Na feira, o jogador aluga um espaço e vende com multiplicador maior.
- E3. A caixa de venda na fazenda vende com multiplicador menor.

## Progressão [depois]
- U1. Lugares, itens à venda e ferramentas são liberados aos poucos, por eventos e correspondências.
- U2. O objetivo é dar tempo ao jogador de se acostumar com cada mecânica.

---

## Menu e configurações [base]
- MN1. Ao abrir o jogo, a primeira tela é o menu inicial.
- MN2. O menu inicial tem "Iniciar jogo" e "Configurações".
- MN3. "Configurações" abre a tela de configurações, que tem um botão para voltar ao menu.
- MN4. As configurações começam só com a parte de vídeo. Outras partes (som, controles) vêm depois.
- MN5. A troca entre telas é instantânea, sem animação (W5, W6).
- VD1. O vídeo tem: monitor, modo de janela (janela ou tela cheia), resolução, frequência e V-Sync.
- VD2. O monitor escolhido é onde o jogo roda. Só aparecem os monitores conectados.
- VD3. A resolução só vale no modo janela e só oferece tamanhos que cabem no monitor escolhido.
- VD4. A frequência mostra a taxa de atualização do monitor e deixa escolher um limite de FPS. O padrão é sem limite (W2). A taxa do monitor em si é definida pelo sistema, não pelo jogo.
- VD5. O V-Sync vem ligado por padrão (W2).
- VD6. As mudanças só valem ao clicar em "Aplicar", que também as salva. As configurações salvas são aplicadas ao abrir o jogo.

---

## Estado e save [base]
- SV1. O jogo tem um estado: onde o jogador está e as cartas de cada local, na ordem (Z3). O que o jogo passar a guardar depois entra no mesmo estado.
- SV2. Ao chegar a um local, o jogo salva sozinho (autosave).
- SV3. Há um só save, sobrescrito a cada autosave (a confirmar).
- SV4. O estado é do motor (Z1) e se converte em dados simples. O save guarda esses dados com a versão do formato, e um save ilegível ou de versão desconhecida é ignorado, sem derrubar o jogo.
- SV5. O menu inicial tem "Continuar", que carrega o último save e só aparece se houver um.

---

## Arquitetura e testes [base]
- Z1. O motor de regras é separado da interface: classes `RefCounted`, sem `Node`, cena ou UI.
- Z2. A API é de comandos (`apply_recipe`, `advance_time`, `get_state`). A interface só chama a API.
- Z3. A ordem das cartas faz parte do estado e do save.
- Z4. RNG com seed, para simulações reproduzíveis.
- Z5. Testes unitários com GUT ou gdUnit4.
- Z6. Simulação longa em modo headless com bots e métricas (dias até falir, saldo médio, taxa de atraso).
- Z7. Balanceamento inicial com métricas reais de peso, capacidade e energia, ajustado depois para ser divertido. Tempos de cultivo são comprimidos.
- Z8. O núcleo de cartas e áreas é feito para evoluir: propriedades de carta e áreas são dados extensíveis, para suportar os sistemas de `pendencias-futuras.md` sem reescrever.

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
- Efeito do debuff "cansado" (tamanho e duração).
- Onde o jogador dorme quando a meia-noite o pega longe de casa.
- Se o jogador pode dormir antes das 22:00 e o que acontece com o resto do dia.
- Se os prazos das contas e os juros (D6) usam a virada de dia.
- Limites de peso da mochila e dos storages.
- Efeito do debuff da mochila pesada.
- Valores e frequência das contas.
- O que torna duas cartas "iguais" para somar (C4).
- Como estágios diferentes de plantio convivem num mesmo contador de terra arada.
- Peso por carta ou por unidade (sementes e outros itens empilhados).
- Água do regador: quanto cada m² precisa e como reabastece.
- O que machado e serrote fazem de diferente.
- Se a caixa de venda paga mais ou menos que a venda em lote (E3).
- Se o aluguel do espaço na feira é por dia e quantas cartas cabem.
- Fim do jogo e condição de vitória (fica para depois).
- Quais cartas são móveis e carregáveis (terra arada, terra semeada, animais, construções).
- Como consertar a enxada enferrujada, o regador furado e a roça danificada, e se os status e a manutenção entram na base, já que o estado inicial os usa.
- Se o container de venda em lote e a caixa de venda na fazenda (E3) são a mesma coisa, e quando ele paga.
- Para onde vai o item anexo de uma carta lida (mochila ou chão).
- Se o AR10 vale só para storage e veículo ou também para a mochila, e se fechar o storage é clicando no ícone aberto na mão (a mochila fecha clicando nela, AR8).
- Quantos itens cabem na mão (um ou dois), para que servem e se contam no peso carregado.
- Se a área da mão fica mesmo na lateral.
- Se a carta do veículo na mão conta entre os itens segurados (um ou dois) e como se abre ou fecha o veículo (L8).
- Relação entre os status das cartas e os buffs e debuffs (ver `pendencias-futuras.md`).
- Clima, estações.
- Se o jogo também salva ao iniciar um jogo novo, ao dormir e na virada de dia, e se haverá mais de um save (SV3).
- O que fazer com "Iniciar jogo" quando já existe um save (hoje o save antigo só é trocado no primeiro autosave).
- Se o menu inicial ganha "Sair" (hoje há "Iniciar jogo", "Configurações" e, com save, "Continuar").
- Se a frequência deve ser só informativa com limite de FPS (VD4) ou se há outra intenção para ela.
