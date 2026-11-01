# Fields of Cards - Estórias dos suplementos

Quebra das features de `features-suplementos.md` em estórias pequenas, no mesmo formato de `estorias-mecanica.md`. Cada estória cita as regras de `regras-suplementos.md` pelos códigos. **Depende** marca uma decisão ainda em aberto; a primeira versão implementada usa um valor provisório, registrado em `implementacao-status.md`.

---

## 23. Animais [depois]

**US-23.1** Como jogador, quero animais como cartas com comida, limpeza e felicidade, para cuidar deles.
Aceite: um animal mostra os três medidores, que caem com o passar dos dias.
Regras: A1, T5

**US-23.2** Como jogador, quero dar ração, limpar e brincar com o animal, para os medidores subirem.
Aceite: ração + animal sobe comida; limpar o animal ou o celeiro sobe limpeza; brincar sobe felicidade. Tudo por receitas.
Regras: A2

**US-23.3** Como jogador, quero que o animal morra se ficar muito tempo sem comida ou muito deprimido.
Aceite: comida zerada por dias seguidos ou felicidade zerada por dias seguidos faz o animal morrer.
Regras: A3
Depende: quantos dias; a água (só comida entra).

**US-23.4** Como jogador, quero que a produção do animal dependa de quão bem ele está.
Aceite: na virada do dia, uma galinha bem cuidada põe ovo; uma mal cuidada, não.
Regras: A4, T5

**US-23.5** Como jogador, quero cinco rações (orgânico, manutenção, postura, engorda e crescimento), cada uma com um efeito.
Aceite: as rações são cartas de dados, com efeito próprio sobre o animal.
Regras: A5
Depende: efeito exato de cada ração.

**US-23.6** Como jogador, quero vender, manter ou mandar o animal para o corte.
Aceite: vender dá dinheiro; o corte dá carne; manter não faz nada.
Regras: A6

---

## 24. Construções [ideia]

**US-24.1** Como jogador, quero construir fazendo eu mesmo ou contratando um profissional.
Aceite: o profissional entrega qualidade mediana por dinheiro; o jogador começa com qualidade ruim.
Regras: B1, B2, B3
Depende: preço do profissional.

**US-24.2** Como jogador, quero que minha qualidade de construção melhore com o tempo.
Aceite: construir dá pontos da atividade construção, e a qualidade da obra segue a skill.
Regras: B3, K1

**US-24.3** Como jogador, quero que a área de dentro seja igual à de fora e a qualidade afete só o multiplicador.
Aceite: um shed de 6 m² ocupa 6 m² na fazenda, e a qualidade muda o multiplicador dele.
Regras: B4, V5

**US-24.4** Como jogador, quero que as construções percam durabilidade e precisem de reparo.
Aceite: a durabilidade cai com os dias; a recuperação é por reparo (receita).
Regras: B5
Depende: como consertar.

**US-24.5** Como jogador, quero que a construção danificada reduza a eficiência do trabalho dentro dela.
Aceite: abaixo de um limite de durabilidade, a construção fica danificada e o multiplicador cai.
Regras: B6, S4

**US-24.6** Como jogador, quero poucos níveis de construção.
Aceite: cada construção tem um nível pequeno (1 a 3) que define a capacidade.
Regras: B7

**US-24.7** Como jogador, quero armários e barris, e as construções galinheiro, celeiro, poço e shed.
Aceite: a lista existe como dados. Armário: 1 m² e 100 kg.
Regras: B9, B10

**US-24.8** Como jogador, quero fazer conservas em barris, para vender mais caro.
Aceite: barril + item vira conserva, de maior valor de venda.
Regras: B11
Depende: quais itens conservam e quanto tempo leva.

**US-24.9** Como desenvolvedor, quero maquinários dentro das construções.
Aceite: um maquinário pode ser posto numa construção.
Regras: B8
Depende: confirmação de B8.

---

## 25. Skills [ideia]

**US-25.1** Como jogador, quero pontos de skill por atividade, sem variantes.
Aceite: cada atividade acumula pontos próprios.
Regras: K1
Implementada na feature 12.

**US-25.2** Como jogador, quero que mais skill torne a atividade mais produtiva, com ganho decrescente.
Aceite: o nível segue 1 − e^(−x).
Regras: K2, K3
Implementada na feature 12.

**US-25.3** Como jogador, quero ver o nível de skill e, talvez, a chance de algo funcionar.
Aceite: a tela mostra o nível de cada atividade.
Regras: K4
Depende: se mostra a porcentagem de chance (K4).

---

## 26. Mapa e veículos [ideia]

**US-26.1** Como jogador, quero uma vila pequena e próxima, com lojas limitadas, onde fica o achados e perdidos.
Aceite: a vila é um local de primeiro nível, perto, com uma loja pequena; o achados e perdidos passa a ficar nela.
Regras: Q1, H5

**US-26.2** Como jogador, quero dormir na vila pagando.
Aceite: pagar uma hospedagem na vila permite dormir lá.
Regras: Q4
Depende: preço.

**US-26.3** Como jogador, quero uma cidade maior e mais longe, liberada pelo veículo.
Aceite: a cidade maior só pode ser visitada com um veículo.
Regras: Q2, Q3

**US-26.4** Como jogador, quero veículos (bicicleta, motocicleta, camionete, caminhão), cada um com multiplicador de viagem.
Aceite: viajar com o veículo reduz os minutos da viagem.
Regras: Q5, Q6, V5

**US-26.5** Como jogador, quero combustível para os veículos motorizados, e que a bicicleta não use.
Aceite: viajar de moto gasta combustível; a bicicleta não gasta; sem combustível o veículo não anda.
Regras: Q8, Q9

**US-26.6** Como jogador, quero o depósito do veículo, que serve de armazenamento extra mas exige carregar e descarregar.
Aceite: o veículo é um local com área própria; o conteúdo não vem junto sem ser descarregado.
Regras: Q6, Q7, L8

**US-26.7** Como jogador, quero mochilas maiores.
Aceite: uma mochila com mais capacidade aumenta o limite de peso.
Regras: Q10

---

## 27. Pets, pragas e ajudantes [ideia]

**US-27.1** Como jogador, quero cachorros e gatos que espantam as pragas.
Aceite: um cachorro na fazenda evita ataques de raposa; um gato evita ratos.
Regras: Y1

**US-27.2** Como jogador, quero que raposas comam ovos e galinhas e que ratos estraguem plantações.
Aceite: na virada do dia, com chance sorteada (RNG com seed), uma praga sem proteção faz o estrago.
Regras: Y2, Z4
Depende: chances.

**US-27.3** Como jogador, quero contratar ajudantes que fazem tarefas no lugar do jogador.
Aceite: um ajudante contratado executa uma tarefa (regar) por dia; os melhores custam mais e rendem mais.
Regras: Y3
Depende: quais tarefas e preços.

---

## 28. Maquinário [ideia]

**US-28.1** Como jogador, quero máquinas como evolução das ferramentas, gastando combustível.
Aceite: uma máquina é uma ferramenta de qualidade maior que gasta combustível por uso.
Regras: X1, Q9

**US-28.2** Como jogador, quero a lista de máquinas por área (lavoura, madeira, oficina, animais, artesanal, infraestrutura).
Aceite: as máquinas existem como cartas de dados.
Regras: X2–X7

**US-28.3** Como jogador, quero a motosserra, o esmeril, a bomba d'água com irrigação e o trator primeiro.
Aceite: essas quatro funcionam: motosserra corta mais rápido, esmeril afia, bomba liga o poço à irrigação, trator ara mais.
Regras: X8

---

## 29. Outras ideias [ideia]

**US-29.1** Como jogador, quero ervas daninhas no terreno e um ancinho e uma foice para limpá-las.
Aceite: ervas surgem na terra; foice as remove (talvez com algum item de colheita).
Regras: O1
Depende: nível de colheita.

**US-29.2** Como jogador, quero um açude e a criação de peixes.
Aceite: o açude é um local onde peixes crescem com o tempo e podem ser pescados.
Regras: O2
