# Fields of Cards

Jogo de fazenda em cartas feito em Godot 4.x com GDScript. Projeto pessoal, gratuito.

## Antes de implementar qualquer mecânica
Leia `regras-mecanica.md`: regras curtas e numeradas (C2, T1, D5...), organizadas em [base], [depois] e [ideia]. Implemente só o que está em [base] sem pedido; [depois] e [ideia] não entram sem o desenvolvedor pedir. Detalhes sem decisão ficam em "Em aberto": pergunte em vez de decidir.

`regras-suplementos.md` reúne o conteúdo que se acrescenta por cima da mecânica (animais, construções, skills, veículos, maquinário). Não implemente nada de lá sem pedido. Os códigos das regras são únicos nos dois arquivos.

`features-mecanica.md` resume as features globais da mecânica e aponta as regras de cada uma pelos códigos. Use-o como mapa para saber o que depende de quê.

`estorias-mecanica.md` quebra cada feature em estórias pequenas (US-1.1, US-2.3...), com aceite e regras. Trabalhe uma estória por vez, na ordem de [base]. Onde a estória tem "Depende", pergunte ao desenvolvedor antes de decidir.

Primeiro momento: a feature 20 (áreas e movimentação de cartas). Faça o núcleo de cartas e áreas de modo que as pendências de `pendencias-futuras.md` possam ser acrescentadas depois sem reescrever. Não implemente as pendências sem pedido.

`jogo-fazenda-regras.md` é o registro bruto das conversas e ideias, usado como histórico. Quando houver conflito, os arquivos de regras valem.

## Arquitetura
- O motor de regras fica separado da interface: classes `RefCounted`, sem `Node`, cena ou UI.
- A API é um conjunto de comandos (por exemplo `apply_recipe`, `advance_time`, `get_state`). A interface só chama a API e mostra o estado. O jogo e os testes usam o mesmo código.
- A ordem das cartas em cada área faz parte do estado do jogo (e do save).
- Dados de cartas e receitas em `Resource` (`.tres`); conteúdo novo deve ser dado, não código.
- RNG com seed, para simulações reproduzíveis.

## Testes e simulação
- Testes unitários com GUT ou gdUnit4, rodando pela linha de comando.
- Verificação atual (sem GUT ainda): `godot --headless --path . -s tests/check_video_settings.gd`.
- Simulação de longa duração em modo headless com bots, registrando métricas (dias até falir, saldo médio, taxa de atraso).

## Estrutura
- `src/` motor e configuração sem UI (`RefCounted`). `ui/` cenas e scripts de tela. `tests/` verificações.
- A primeira cena é o menu inicial (`ui/main_menu.tscn`). As configurações de vídeo ficam em `src/config/video_settings.gd`.

## Fluidez e conforto (requisito crítico)
O desenvolvedor tem motion sickness, e o jogo precisa ser perfeitamente fluido a 180 Hz.
- Animações com `Tween` (baseadas em tempo, não em frame).
- V-Sync ligado e sem limite artificial de FPS.
- Sem alocações em runtime, sem buscas de nós por frame (cachear referências), object pooling quando fizer sentido, shaders simples.
- Câmera parada: sem tremor de tela, sem zoom ou rolagem automática, animações curtas e suaves.
- Opção de "movimento reduzido" que troca as animações por trocas instantâneas.
- Sinais visuais estáticos (cor, destaque) em vez de animação brusca.
- A fluidez é validada pelo desenvolvedor na própria máquina; não afirme que ficou perfeito sem essa validação.

## Convenções
- Idioma do documento de regras e dos textos do jogo: português do Brasil.
- Unidades do jogo: tempo em minutos, peso em gramas, área em m².
