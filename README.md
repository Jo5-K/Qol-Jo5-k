# Qol - Jo5-k — 0.1.0-beta.1

Qualidade de vida opcional para Pokémon Emerald, Ruby, Sapphire, FireRed e LeafGreen no G1R **0.3.97+ / API 3**.

Copie a pasta `qol_jo5k` do ZIP para `mods/`. Ative o mod no gerenciador. Acesse **START → QOL**, ou suas opções no gerenciador. Todas as opções possuem rótulos em **English / Português** e são salvas pelo sistema nativo. Controle e toque utilizam o menu nativo do G1R.

| Opção | Comportamento |
|---|---|
| Enfermeira sem conversa | Aceita a cura sem pergunta ou diálogo; preserva a máquina, cura, flags, estatísticas e liberação dos controles. Ligada por padrão. |
| Experiência individual / grupo | Nativa ou 50% para os participantes e 50% divididos entre os demais aptos, independentemente de Exp. Share. Um único apto recebe tudo. Vários participantes dividem a metade deles. Ovos, desmaiados e nível 100 não recebem XP. |
| TMs reutilizáveis | Não gasta o TM ao ensinar, inclusive ao substituir um golpe. Venda/descarte continuam normais. |
| HMs sem aprender o golpe | Permite ações de campo sem ocupar golpes do Pokémon. Mantém insígnias, terreno e destinos liberados. Inclui atalhos no submenu do Pokémon. Não modifica o moveset. |
| Desativar ajuda L/R | Bloqueia a ajuda modal nativa de FRLG; não remove outros usos dos botões. |
| Curar após captura | Cura o Pokémon capturado e seus PP, inclusive quando enviado ao PC. |
| Captura garantida | Garante a rolagem de captura em batalhas selvagens elegíveis; não habilita captura de treinadores. |
| Multiplicador de XP | 1x/desligado, 2x, 3x, 5x ou 10x; compõe com a divisão e bônus nativos. |
| Multiplicador de dinheiro | 1x/desligado, 2x, 3x, 5x ou 10x nas recompensas de treinadores; limite monetário nativo preservado. |
| Itens equipados reutilizáveis | Não consome berries e outros consumíveis equipados dos Pokémon do jogador. Não afeta itens de adversários, venda ou itens da mochila. |
| Ovos rápidos | Inicia a eclosão nativa no próximo passo elegível, sem aguardar os ciclos. Não elimina a animação nem manipula ovos inválidos. |
| Flash automático | Remove a máscara de escuridão sem equipar Flash; a opção pode ser desligada imediatamente. Não resolve puzzles de Flash nem altera permanentemente flags/mapas. |
| Textos instantâneos | Remove a revelação letra a letra. Preserva páginas, escolhas e confirmações; não escolhe respostas automaticamente. |

As opções, exceto a enfermeira, começam no comportamento nativo/desligado. As opções de distribuição e multiplicadores usam o valor nativo/1x para desativar. Os modificadores não atuam em link ou tutorial. O manifest declara impacto nas regras de link, para o gerenciador identificar a mudança de regras.

## Experience distribution / modern share

200 XP, seis aptos, um participante: **100 + 20 + 20 + 20 + 20 + 20**. Três aptos: **100 + 50 + 50**. Restos inteiros são distribuídos sem criar ou perder XP antes dos bônus individuais. Lucky Egg, treinador e troca seguem o processo nativo; aprendizagem de golpes e evolução continuam nele.

## Validação desta beta

- Carregador API 3 e menu START nos cinco jogos via SDK oficial.
- Script real extraído da enfermeira de Emerald executado na VM nativa com adaptadores simulados: cura uma vez, sem mensagens, e termina.
- Experiência executada por `Experience.awardFoe`: seis aptos, três/quatro aptos, exclusão de ovos/desmaiados, modo nativo e conservação dos pools.
- Testes específicos de TMs imediatos/assíncronos, venda, ajuda, cura/captura, XP/dinheiro, consumíveis, ovos, Flash, textos, HMs, traduções e restauração.

**Não houve campanha completa, teste em Android ou validação visual de todas as ações de campo nesta execução.** Os scripts reais de Ruby/Sapphire/FRLG não foram executados integralmente; o carregador e as rotas compartilhadas foram testados. Scripts customizados que substituam os símbolos da enfermeira podem precisar de adaptação.

## Technical notes / manutenção

Usa hooks oficiais quando disponíveis e wrappers limitados de funções nativas para recursos sem hook (consumo de TM, dinheiro, máscara de Flash etc.). Não altera arquivos do motor, ROMs ou outros mods. Os wrappers são restaurados ao sair e reutilizam uma lease para recarga. Traduções de nomes/mensagens do jogo permanecem nativas ou fornecidas pelo mod de idioma. Não implementa geração de itens, roubo de itens infinitos ou desbloqueio de insígnias.
