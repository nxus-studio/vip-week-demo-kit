# vip-week-demo-kit

El kit de [vip-week-demo](https://github.com/nxus-studio/vip-week-demo): todo lo que el agente **no**
debe ver. Trae los pasos de cada acto, los prompts, los tests ocultos, una solución de referencia, el
export de SAP del acto 2 y lo que medimos.

**Clónalo fuera del repo del demo.** El agente puede leer cualquier archivo y cualquier rama de git de
su proyecto. Por eso las respuestas viven aquí, y estos scripts trabajan sobre el clon del demo desde
fuera. Nada en el demo (ni archivos, ni ramas, ni mensajes de commit) menciona este kit; el enlace está
solo en la descripción del repo en GitHub, que el agente no ve. No es una barrera de seguridad: un
agente que corre `find /` lo encuentra, así que tampoco lo menciones en tus prompts. Si quieres estar
seguro, revisa al final los comandos del agente (en Claude Code, la transcripción de la sesión) y busca
`vip-week-demo-kit`.

```bash
git clone https://github.com/nxus-studio/vip-week-demo      ~/vip-week-demo
git clone https://github.com/nxus-studio/vip-week-demo-kit  ~/vip-week-demo-kit
cd ~/vip-week-demo && npm ci && npm test        # verde: los bugs no se ven en la suite
```

Necesitas Node 20+, git y un agente con MCP (Claude Code, Cursor, Codex, OpenCode…). El demo ya trae la
configuración de `lemma init`.

**Importante:** el bug de zona horaria solo aparece si el proceso **no** corre en hora de Ciudad de
México. Arranca el agente con `TZ=UTC`, por ejemplo `TZ=UTC claude`.

| Acto | Qué ves | Preparación |
| --- | --- | --- |
| 1. VIP-WEEK | Juan investiga y Ana lo encuentra en su primera búsqueda | ninguna |
| 1b. STALE | Un compañero renombra una función y la memoria se marca `STALE` | `setup.sh <demo> stale` |
| 1c. Corrección | Ana corrige la memoria de Juan y en la máquina de Juan aparece reemplazada | igual que 1b |
| 2. SAP | Un dato que solo está en un archivo de Juan | `setup.sh <demo> sap`, y en la máquina de Juan `setup.sh finanzas` |

`./setup.sh <demo> reset` regresa el clon a `origin/main`. Descarta los cambios locales y el `.lemma/`
del proyecto.

## Qué se demuestra (y qué no)

1. Una sesión investiga y guarda lo que aprendió, **ligado a las funciones de las que depende**.
2. Una sesión nueva (otro día, u otra persona con Lemma Cloud) lo encuentra en su primera búsqueda, con
   su autor, y marcado `fresh` en *su* checkout.
3. Si alguien cambia de verdad ese código o renombra la función, la memoria regresa `STALE` en lugar de
   seguir afirmando algo que ya no es cierto. Un cambio solo de comentarios no la invalida.
4. Cuando el dato clave **no está en el repo** (acto 2), la memoria de un compañero es la diferencia
   entre acertar y entregar un arreglo que parece bueno y no lo es.

Lo que **no** afirmamos: que Lemma ahorre dinero aquí. En el acto 1 la segunda sesión cuesta lo mismo y
arregla igual con o sin memoria, porque el bug se redescubre leyendo git. En el acto 2 la memoria cuesta
*más*, porque el agente implementa la regla completa. Todo está medido abajo.

## Acto 1: VIP-WEEK

La promoción VIP-WEEK da 10% a clientes gold del 1 al 7 de marzo de 2026. Finanzas reporta dos síntomas:
las facturas reimpresas y el reporte mensual muestran un total menor al cobrado, y los gold que
compraron la última noche no recibieron descuento. Cada síntoma tiene su causa en la historia de git, y
hay un commit que solo *parece* culpable.

**Sesión 1, Juan (investigar, sin cambiar código):**

> Finanzas dice que las facturas de la semana VIP (promoción VIP-WEEK: 10% para clientes gold, del 1 al 7
> de marzo de 2026) están mal de dos formas: (a) las facturas reimpresas y el reporte mensual de ventas
> muestran un total menor al que se le cobró al cliente; (b) los clientes gold que compraron la última
> noche (7 de marzo, como a las 8pm hora de Ciudad de México) no recibieron descuento. Investiga la causa
> de cada problema, qué commit la introdujo y si algo en el historial solo parece culpable. No cambies
> código. Deja tus hallazgos para que otra sesión los use.

**Sesión 2, Ana (sesión nueva, sin contexto):** con Lemma Cloud, en otra máquina; sin Cloud, en la misma
máquina con `/clear` o una terminal nueva.

> Finanzas reportó dos problemas con la promoción VIP-WEEK: las facturas reimpresas y el reporte de ventas
> muestran un total menor al cobrado, y los pedidos gold de la última noche (7 de marzo, hora de Ciudad de
> México) no recibieron descuento. Arregla los dos. Mantén los tests en verde y agrega tests de regresión.

Fíjate en la primera búsqueda de memoria del agente de Ana: ahí aparece lo que dejó Juan. Al terminar,
califica:

```bash
~/vip-week-demo-kit/grade.sh ~/vip-week-demo vip    # en el commit base: 1/6 en UTC, 3/6 en CDMX
```

`patches/vip-fix.patch` es una solución de referencia (6/6 en las dos zonas).

### 1b. STALE

Después de la sesión 1, en la máquina donde se va a leer la memoria:

```bash
~/vip-week-demo-kit/setup.sh ~/vip-week-demo stale
```

Esto agrega un commit de "un compañero" que renombra `isActive` a `isPromotionActive`. En una sesión
nueva, la memoria de Juan aparece como `STALE — changed here since: src/promotions.ts::isActive`. Solo
esa parte: lo que dice de `applyPromotion` sigue `fresh`.

### 1c. Corrección

Con la memoria `STALE`, el agente de Ana puede corregirla con `update_memory` sobre el id `[team]`. La
versión corregida reemplaza a la del equipo, anclada al checkout de Ana. En la máquina de Juan, la
siguiente búsqueda muestra `[team] <id> (by ana, …)` con `Replaces team memory <id> (by juan).`, y su
copia local queda marcada como reemplazada.

Un límite que conviene saber: la versión corregida sigue solo los símbolos que todavía existen en el
checkout de Ana. Como `isActive` ya no existe ahí, deja de seguir esa parte y no agrega
`isPromotionActive`.

## Acto 2: lo que no está en el código (regla de SAP)

Finanzas dice que nuestros totales no cuadran por centavos con SAP. Juan tiene el export de SAP de marzo
(datos ficticios) **fuera del repo**; Ana no lo tiene. De ese export se deduce la regla que usa SAP para
el descuento, el redondeo y el IVA, que no está escrita en ningún lado del código.

En las dos máquinas:

```bash
~/vip-week-demo-kit/setup.sh ~/vip-week-demo sap      # el acto 1 ya arreglado
```

Solo en la de Juan:

```bash
~/vip-week-demo-kit/setup.sh finanzas                 # ~/finanzas/sap-export-marzo.csv
```

**Sesión de Juan:**

> Finanzas dice que los totales de nuestras facturas no cuadran por centavos con SAP, sobre todo en la
> semana VIP. Te dejaron el export de SAP de marzo en ~/finanzas/sap-export-marzo.csv (está fuera del
> repo; la última columna es lo que calculó nuestro sistema). Averigua exactamente qué regla usa SAP para
> el descuento, el redondeo y el IVA, y en qué difiere de nuestro cálculo. No cambies código. Deja tus
> hallazgos para que el equipo los use.

**Sesión de Ana**, en otra máquina con Cloud. Sin Cloud, una sesión nueva en la misma máquina, con
`~/finanzas` movido a otro lado:

> Finanzas dice que los totales de nuestras facturas no cuadran por centavos con SAP, sobre todo en la
> semana VIP. Haz que nuestro cálculo de totales cuadre exactamente con SAP. Mantén los tests en verde y
> agrega tests de regresión.

```bash
~/vip-week-demo-kit/grade.sh ~/vip-week-demo sap      # 4 pedidos que no están en el export; base: 0/4
```

## Con Lemma Cloud (dos laptops, dos personas)

Cada quien conecta una vez con la key de su equipo:

```bash
lemma cloud login
lemma cloud status
```

La memoria de Juan le aparece a Ana como `[team] <id> (by juan, today, fresh here)`. La frescura se
revisa contra el checkout de quien la lee, no contra el de quien la escribió. Cloud guarda el texto de
las memorias compartidas (con secretos redactados) y los hashes de los archivos de los que dependen,
nunca el repositorio. Acceso de equipo: [lemma.nxus.studio/#cloud](https://lemma.nxus.studio/#cloud).

## Lo que medimos

Claude Code (sonnet) en modo headless, Lemma 1.45.3, dos contenedores Docker con `TZ=UTC`, 2 de
noviembre de 2026. Juan hizo su sesión una vez; Ana hizo la suya cinco veces con la memoria de equipo de
Juan y cinco sin ella, intercaladas. En todas, el repo del demo no tenía el kit, ni en archivos ni en
ramas.

**Acto 1:**

| Sesión de Ana | Corridas | Tests ocultos (UTC / CDMX) | Costo medio | Minutos | Turnos |
| --- | --- | --- | --- | --- | --- |
| con la memoria de Juan | 5 | 6/6 y 6/6 en las 5 | $0.72 | 2.7 | 34.0 |
| sin memoria | 5 | 6/6 y 6/6 en las 5 | $0.75 | 3.0 | 33.8 |

Sin diferencia medible: este bug se redescubre leyendo git, y el agente lo hace. Lo que sí cambia es que,
con la memoria, Ana llega sabiendo qué encontró Juan y si sigue siendo cierto en su código.

**Acto 2 (SAP):**

| Sesión de Ana | Corridas | Tests ocultos SAP | Costo medio | Minutos |
| --- | --- | --- | --- | --- |
| con la memoria de Juan | 5 | 4/4 en las 5 | $1.09 | 4.3 |
| sin memoria | 5 | 1/4 en las 5 (ninguna correcta) | $0.75 | 2.7 |

Sin la memoria, Ana adivinó siempre un tercio de la regla y dejó los tests visibles en verde: un arreglo
que parece bueno. Con la memoria acertó siempre, y costó unos $0.35 más porque implementó la regla
completa. Cinco corridas por brazo es poco para afinar el costo, pero 5/5 contra 0/5 en correctitud es
claro.

## Por qué existe este kit

En un ensayo, con todo en el mismo repo, el agente de Ana encontró el export de SAP en una rama con
`git log --all` y corrió los tests ocultos mientras arreglaba. Ese ensayo no vale como prueba. Desde
entonces, nada que dé la respuesta vive en el repo del demo.

En el siguiente ensayo, ya con el kit aparte, el README del demo todavía lo mencionaba, y el agente de
Ana lo buscó con `find`. Lo encontró y no lo abrió (SAP 4/4 con la memoria de Juan). Desde entonces el
demo no lo menciona en ningún lado.

MIT. Datos y código ficticios.
