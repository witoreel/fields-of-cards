# Fields of Cards

Jogo de fazenda em cartas feito em Godot 4.x com GDScript. Projeto pessoal, gratuito.

## Antes de implementar qualquer mecânica
Leia `jogo-fazenda-regras.md`. Ele é a fonte das regras do jogo e é atualizado conforme as ideias evoluem. A prioridade é a mecânica base; o que está em "Ideias futuras" não deve ser implementado sem pedido.

## Arquitetura
- O motor de regras fica separado da interface: classes `RefCounted`, sem `Node`, cena ou UI.
- A API é um conjunto de comandos (por exemplo `apply_recipe`, `advance_time`, `get_state`). A interface só chama a API e mostra o estado. O jogo e os testes usam o mesmo código.
- A ordem das cartas em cada área faz parte do estado do jogo (e do save).
- Dados de cartas e receitas em `Resource` (`.tres`); conteúdo novo deve ser dado, não código.
- RNG com seed, para simulações reproduzíveis.

## Testes e simulação
- Testes unitários com GUT ou gdUnit4, rodando pela linha de comando.
- Simulação de longa duração em modo headless com bots, registrando métricas (dias até falir, saldo médio, taxa de atraso).

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
