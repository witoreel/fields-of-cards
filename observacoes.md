# Observações do desenvolvedor sobre a tela

Anotadas sem implementar. A página de teste está em `mockup/tela-jogo.html`.

## Tela do jogo
- Metragem ocupada da fazenda e horário ficam no canto superior direito.
- Fonte menor.
- Botão de engrenagem à direita de tudo, para voltar ao menu.
- O nome da área de cartas fica no fundo (background) da área, para ganhar pixels.
- (substituído pela 2ª rodada) As cartas usavam toda a altura da área.
- (2ª rodada) Nem toda a tela precisa ser de cartas: cartas com altura padrão; uma área de cartas em cima, uma embaixo e uma em cada lado.
- (3ª rodada) Carta um pouco maior (108 x 132); laterais menores (mais baixas) e com duas colunas.
- (4ª rodada) As áreas laterais usam toda a altura disponível entre a de cima e a de baixo (continuam com duas colunas).
- (5ª rodada) No fundo da área de cima, mostrar o nome do local (ex.: Fazenda) em vez da palavra "Local". Com storage aberto, mostrar o nome do storage.
- (6ª rodada) O chão vai para o centro: duas fileiras de cartas de altura, com bastante padding, sem ocupar o centro todo. A área da direita fica contextual (exemplo: storage aberto). Isso muda o AR4, que põe o storage em cima no lugar do local; a confirmar.
- (7ª rodada) A engrenagem não pode criar uma coluna que dê margem à direita da tela: ela fica na barra de cima, no canto direito, e o resto usa a largura toda.
- (8ª rodada) Tirar o nome do local da barra de cima (já aparece na área). As opções de locais abrem no menu contextual da direita quando o jogador escolhe navegar pelo mapa (botão "Mapa").
- (9ª rodada) Dock de ícones suspenso na área central, ícones grandes, estilo Cairo Dock, com mapa, mão e mochila (substitui o botão Mapa da barra de cima). Cada ícone mostra ou esconde a sua área.
- (10ª rodada) Ícone do chão no dock (mostra ou esconde a área do chão). Pela regra AR5 o chão está sempre disponível: aqui o ícone só controla se ele aparece na tela.
- (11ª rodada) Cartas 20% maiores (130 x 158 px).
