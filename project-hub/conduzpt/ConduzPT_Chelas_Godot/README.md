# ConduzPT — Chelas / Lisboa — Alfa geográfica Godot 4

## O que foi realmente construído
Projeto Godot 4 com câmara em primeira pessoa, carro simplificado, setas para conduzir, caixa manual simplificada, terreno 3D e importador **ao vivo** de ruas e edifícios OpenStreetMap num quadrado aproximado de 700 m centrado na Rua André Vidal Negreiros (Chelas). A geometria só aparece após o download de dados reais. Se falhar, não é substituída por ruas fictícias.

**ATENÇÃO:** não foram descarregados dados OSM para dentro deste ZIP, porque o ambiente de criação não tinha acesso à API. O projeto precisa de internet na primeira execução ou de um ficheiro `dados/chelas.osm.json` fornecido por ti. Não foi testado num editor Godot instalado. Não é um simulador de exame pronto.

## Como abrir
1. Instala Godot Engine 4.2 ou superior (https://godotengine.org/download/).
2. Abre Godot > Importar > escolhe `project.godot` desta pasta.
3. Executa com F6/F5. Aguarda a mensagem «OSM REAL» e as ruas a aparecer.
4. Setas ↑ acelerar, ↓ travar, ←/→ direção. Mantém **Shift** e prime **1** para primeira mudança; larga Shift e acelera. Shift + 2–5 muda de velocidade; Shift + 0 é ponto morto. Espaço trava. R reposiciona.

## Se a API estiver indisponível
1. Abre https://overpass-turbo.eu/
2. Cola esta consulta e carrega em **Run**:
```
[out:json][timeout:25];
(
 way["highway"](38.751283,-9.118781,38.757583,-9.110701);
 way["building"](38.751283,-9.118781,38.757583,-9.110701);
);
out body;
>;
out skel qt;
```
3. Exporta > dados brutos > JSON e guarda como `dados/chelas.osm.json`.
4. Volta a abrir o projeto. O ficheiro local é utilizado se o pedido automático falhar.

## O que é real e o que não é
- **Real quando importado:** nós e traçados OSM, alguns atributos como tipo de via, número de faixas e níveis dos edifícios quando existem.
- **Aproximado:** largura das vias quando faltam dados, edifícios como caixas envolventes (não reproduzem a forma), altimetria plana, posição inicial do carro, física, detetor de saída de via.
- **Ainda inexistente:** sinais e semáforos verificados, marcações, trânsito, peões, rotas oficiais, regras de prioridade, texturas realistas, motor/embraiagem fiel, seleção de sentidos permitidos, relatórios de exame.
- **Nunca assumir:** que o traçado OSM equivale à sinalização atual no terreno ou a percurso oficial do IMT.

## Referências e licenças
Dados © OpenStreetMap contributors, ODbL 1.0: https://www.openstreetmap.org/copyright
Centro APEC: https://www.apec.pt/contactos/
Coordenada de referência da rua (não é geocodificação exata da porta 30): https://www.codigos-postal.com/lisboa/lisboa/lisboa/rua-andre-vidal-negreiros/
Este código é um protótipo demonstrativo independente, não afiliado ao IMT ou à APEC.
