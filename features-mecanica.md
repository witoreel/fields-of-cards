# Fields of Cards - Features globais da mecânica

Visão geral das features que atravessam o jogo todo. Cada uma reúne regras de `regras-mecanica.md` pelos seus códigos. Os suplementos (`regras-suplementos.md`) usam estas mesmas features, sem criar sistemas novos.

Etiquetas: **[base]** se implementa primeiro, **[depois]** vem em seguida.

---

## Primeiro momento

### 20. Áreas e movimentação de cartas [base]
As cartas vivem em cinco áreas (mão, mochila, storage, local e stage, o chão), que não precisam estar visíveis ao mesmo tempo. A mão, talvez na lateral, guarda um ou dois itens segurados, a carta da mochila e, se houver, a carta do veículo, de acesso rápido. Selecionar a carta da mochila a abre embaixo, e clicar nela aberta a fecha. Selecionar a carta de um storage o abre em cima, no lugar do local, e o ícone dele aberto vai para a mão; ao fechar, a carta volta para o local (o mesmo vale para o veículo). O chão está sempre disponível, e as cartas móveis passam de uma área aberta a outra. As cartas têm propriedades que se combinam (local, ferramenta, acumulável, móvel, inerente ao local, veículo) e podem ter buffs e debuffs. O núcleo é feito para evoluir e suportar as pendências futuras.
Regras: AR1–AR10, C1, C7, C8, C9, L8, Z8

### 21. Menu e configurações [base]
O jogo abre num menu inicial com "Iniciar jogo" e "Configurações", sem animação entre telas. As configurações começam pelo vídeo: monitor, modo de janela, resolução, frequência (taxa do monitor e limite de FPS) e V-Sync. As escolhas são aplicadas com um botão, salvas e reaplicadas ao abrir o jogo.
Regras: MN1–MN5, VD1–VD6

### 22. Estado e save [base]
O jogo tem um estado do motor (onde o jogador está e as cartas de cada local, em ordem), que vira dados simples e é salvo sozinho a cada local em que o jogador chega. O menu oferece "Continuar" quando há um save.
Regras: SV1–SV5

---

## Núcleo

### 1. Receitas por arrastar [base]
Arrastar uma carta sobre outra executa uma receita (A + B = C), com custo em minutos e consumo ou desgaste da ferramenta. Conteúdo novo é só dado. No dia sem rega, o crescimento da roça fica congelado.
Regras: C2, C3, C6, R1–R7, R9

### 2. Relógio e dia [base]
Toda ação gasta minutos, ainda que o custo seja zero, e o crescimento e os eventos seguem um relógio global. O dia termina à meia-noite, e o jogador acorda às 06:00. Passar das 22:00 acordado gera o debuff "cansado". Plantas crescem rápido e animais em ritmo mais realista (ainda não definitivo).
Regras: T1–T5, T7–T10

### 3. Cartas, áreas e ordem [base]
Cartas pertencem a áreas (local, storage, mochila), podem ser reordenadas e a ordem é preservada. Cartas iguais que chegam ao mesmo destino se somam, com sinal visual.
Regras: C1, C4, C5, L2

### 4. Locais navegáveis [base]
Locais são cartas eternas que mudam onde o jogador está, cada um com a sua área de cartas. Itens passam de um local a outro pela mochila.
Regras: L1, L3, L4, L5, L6

### 5. Peso e capacidade [base]
Toda carta móvel tem peso em gramas, exceto o dinheiro, e locais não têm peso. A mochila e os storages têm limite de peso, e recipientes como o regador têm volume em gramas, gasto a cada uso.
Regras: P1, P2, P3, P5

### 6. Área da fazenda [base]
A fazenda tem um limite global em m² somando todos os locais. Terra bruta não ocupa espaço, e terra arada ocupa m² e tem um contador. Terra bruta, árvores e água de riacho são infinitas.
Regras: L7, N1, N2, N3

### 7. Economia [base]
Itens são vendidos por dinheiro, e o dinheiro é uma carta de nota, sem peso. Compras gastam dinheiro e contas são cartas com prazo e valor. Pagar custa dinheiro e o tempo de ir à cidade, e a dívida gera multa. A venda em lote é feita num container na fazenda.
Regras: D1, D2, D3, D4, D5, D9, E1

### 8. Dívida e falência [base]
O tempo está ligado às dívidas, e a falência encerra o jogo. A consequência (perder tudo, voltar bem atrás, ou a polícia prender o jogador) está em estudo. A condição de vitória fica para depois.
Regras: D6, D7, D8, F1, F2, F3

### 9. Estado, testes e simulação [base]
O motor de regras é separado da interface e funciona por uma API de comandos. A ordem das cartas entra no save. O RNG tem seed, e há testes unitários e simulação longa com bots. O balanceamento parte de métricas reais e é ajustado para ser divertido.
Regras: Z1, Z2, Z3, Z4, Z5, Z6, Z7

### 10. Fluidez e conforto [base]
Fluido a 180 Hz, com animações por `Tween`, câmera parada, movimento reduzido opcional e sinais visuais estáticos. O conforto é validado na máquina do desenvolvedor.
Regras: W1–W7

---

## Camadas sobre o núcleo

### 11. Ações com tempo variável [depois]
O resultado de uma ação depende do tempo gasto, escolhido num diálogo com slider.
Regras: V1, V2

### 12. Multiplicadores [depois]
O resultado das ações recebe multiplicadores: qualidade da ferramenta, skill, construção onde se trabalha, roça, e o local de venda (feira ou caixa na fazenda). Os suplementos acrescentam outros, como o multiplicador de viagem do veículo.
Regras: V3, V4, V5, R8, E2, E3

### 13. Desgaste e manutenção [depois]
Ferramentas têm durabilidade que cai com o uso, sem quebrar: quanto menor, mais tempo a mesma ação leva. As de corte têm fio. Afiar e limpar diminuem a degradação, e guardar ferramenta suja ou molhada a aumenta. Tiers de ferramenta (barata a premium) são uma ideia.
Regras: G1, G2, G3, G4, G5, G6

### 14. Status de cartas [depois]
Cartas têm status (sujo, molhado, enferrujado) e também podem ter buffs e debuffs. A relação entre os dois é uma pendência futura.
Regras: S1, S2

### 15. Buffs e debuffs [depois]
Alimentos geram buffs, a mochila pesada gera debuff, passar das 22:00 acordado gera o debuff "cansado", e construção danificada gera debuff no seu multiplicador.
Regras: P4, S3, S4, T9

### 16. Chão e achados e perdidos [depois]
Cartas novas chegam ao chão do local e o jogador escolhe onde ficam. O chão não tem limite, mas no fim do dia o que sobra vai para o achados e perdidos, por 7 dias, com aviso no correio.
Regras: H1, H2, H3, H4, H5

### 17. Correio [depois]
Uma caixa de correio é um storage de cartas de correspondência, lidas ao clicar, sem gastar tempo. Traz avisos, dicas e promoções, sempre no início do dia, e a carta lida pode vir com um item anexo, como a carta da conta.
Regras: M1, M2, M3, M4, M5, T6

### 18. Progressão e desbloqueio [depois]
Lugares, itens à venda e ferramentas são liberados aos poucos por eventos e correspondências, para o jogador se acostumar com cada mecânica.
Regras: U1, U2

---

## Início do jogo

### 19. Estado inicial [base]
O jogo começa com uma enxada enferrujada, um regador furado e um pouco de dinheiro. A roça inicial está danificada, precisando de manutenção, e uma mensagem de boas-vindas no correio traz algumas sementes.
Regras: I1, I2, I3
