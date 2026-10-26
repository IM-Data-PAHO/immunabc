# Uso de los datos de ejemplo

[🌐 Read this in
English](https://im-data-paho.github.io/immunabc/articles/en/example_datasets_en.md)

## Fundamento

El paquete immunABC incluye conjuntos de datos de ejemplo para ayudar a
los usuarios a entender cómo funcionan sus herramientas. Estos datos
simulan el sistema de información de inmunización de un país ficticio y
están estructurados para funcionar con las funciones del paquete. Esta
viñeta presenta cada conjunto de datos y explica cómo se usan en los
distintos módulos.

## Glosario

### Divisiones político-geográficas

A lo largo de esta viñeta se hace referencia a distintos niveles de
división político-geográfica. Estos niveles son definidos por cada país
o territorio y pueden recibir nombres diferentes. immunABC no depende de
esos nombres locales; por eso, el usuario debe recodificar sus variables
para ajustarlas a la estructura que utiliza el paquete.

En concreto, immunABC puede distinguir tres niveles administrativos que,
listados del nivel superior al inferior, son: ADM0, ADM1 y ADM2.

1.  ADM0: El país. Este es el nivel administrativo más alto.
2.  ADM1: La primera subdivisión geográfica del país. ADM0 contiene
    varias subdivisiones ADM1.
3.  ADM2: La segunda subdivisión geográfica del país. Cada ADM1 contiene
    varias subdivisiones ADM2.

![](ADM_explanation.svg)

### Nombres de vacunas

Los conjuntos de datos de ejemplo utilizan una convención específica
para nombrar las dosis de vacunas. Es posible que esta convención no
coincida con la que usa su país o institución, pero esto no afecta el
uso del paquete si los nombres se aplican de manera consistente.

Por ejemplo, los nombres de las vacunas utilizados en el paquete
immunABC son:

| Abreviatura | Nombre completo                                          |
|-------------|----------------------------------------------------------|
| SRP1        | Vacuna contra sarampión, rubéola y paperas (1.ª dosis)   |
| DTP1        | Vacuna contra difteria, tétanos y tos ferina (1.ª dosis) |
| DTP2        | Vacuna contra difteria, tétanos y tos ferina (2.ª dosis) |
| DTP3        | Vacuna contra difteria, tétanos y tos ferina (3.ª dosis) |
| BCG RN      | Vacuna Bacillus Calmette–Guérin (al nacer)               |
| YFV1        | Vacuna contra la fiebre amarilla (1.ª dosis)             |

## Lista de conjuntos de datos de ejemplo

### immunABC.EIR

El conjunto de datos
[`immunabc::immunABC.EIR`](https://im-data-paho.github.io/immunabc/reference/immunABC.EIR.md)
es el más importante del paquete. Proporciona un ejemplo de Registro
Nominal de Vacunación electrónico (RNVe). Es una tabla nominal simulada
con eventos individuales de vacunación. Cada fila corresponde a una
vacunación e incluye información sobre la residencia de la persona, el
lugar donde fue vacunada, su fecha de nacimiento y la dosis recibida.

``` r

immunABC.EIR %>% head() %>% kable(caption = "Ejemplo de Registro Nominal de Vacunación electrónico")
```

| ID | date_birth | date_vax | ADM1_residence | ADM2_residence | ADM1_occurrence | ADM2_occurrence | dose |
|---:|:---|:---|:---|:---|:---|:---|:---|
| 191997 | 2023-08-08 | 2023-12-26 | ADM1_4 | ADM2_4_35 | ADM1_4 | ADM2_4_35 | DTP2 |
| 212189 | 2023-12-20 | 2023-12-26 | ADM1_5 | ADM2_5_61 | ADM1_5 | ADM2_5_61 | BCG RN |
| 118063 | 2022-09-15 | 2023-12-26 | ADM1_2 | ADM2_2_5 | ADM1_2 | ADM2_2_5 | DTP1 |
| 118063 | 2022-09-15 | 2023-12-26 | ADM1_2 | ADM2_2_5 | ADM1_2 | ADM2_2_5 | YFV1 |
| 130751 | 2022-10-27 | 2023-12-12 | ADM1_5 | ADM2_5_55 | ADM1_5 | ADM2_5_55 | YFV1 |
| 136532 | 2021-09-21 | 2023-12-26 | ADM1_3 | ADM2_3_12 | ADM1_3 | ADM2_3_12 | SRP1 |

Ejemplo de Registro Nominal de Vacunación electrónico {.table
style="width:100%;"}

- `ID`: Número único de identificación de la persona.
- Fecha de nacimiento (`date_birth`): Fecha de nacimiento de la persona.
- Fecha de vacunación (`date_vax`): Fecha del evento de vacunación.
- ADM1: Primer nivel administrativo geográfico del país.
- ADM2: Segundo nivel administrativo geográfico del país.
- Lugar de residencia (`Residence`): Lugar donde vive la persona.
- Lugar de vacunación (`Occurrence`): Lugar donde ocurrió la vacunación.
- Dosis (`dose`): Variable combinada que representa el tipo de vacuna y
  su número de dosis correspondiente. Por ejemplo, DTP1 se refiere a la
  primera dosis de una vacuna que contiene componentes de difteria,
  tétanos y tos ferina.

### immunABC.schedule

El conjunto de datos
[`immunabc::immunABC.schedule`](https://im-data-paho.github.io/immunabc/reference/immunABC.schedule.md)
define el esquema nacional de vacunación, con cada dosis y su edad
recomendada de administración (en días). Esta tabla permite determinar
si una persona tiene las vacunas que le corresponden según el esquema.

``` r

immunABC.schedule %>% kable(caption = "Ejemplo de esquema de vacunación")
```

| dose   | age_schedule | age_schedule_low | age_schedule_high |
|:-------|-------------:|-----------------:|------------------:|
| SRP1   |          365 |              360 |               420 |
| DTP1   |           60 |               54 |                90 |
| DTP2   |          120 |              116 |               150 |
| DTP3   |          180 |              176 |               210 |
| BCG RN |            0 |                0 |                28 |
| YFV1   |          365 |              360 |               420 |

Ejemplo de esquema de vacunación {.table}

- Dosis (`dose`): Variable combinada que representa el tipo de vacuna y
  su número de dosis correspondiente. Por ejemplo, DTP1 se refiere a la
  primera dosis de una vacuna que contiene componentes de difteria,
  tétanos y tos ferina.
- Edad programada (`age_schedule`): Edad recomendada de administración
  de la dosis, en días.
- Límite inferior de edad (`age_schedule_low`): Límite inferior de la
  edad objetivo, en días.
- Límite superior de edad (`age_schedule_high`): Límite superior de la
  edad objetivo, en días.

> **Nota**
>
> Los nombres de las dosis en la columna `dose` deben coincidir
> exactamente con los del conjunto de datos `immunABC.EIR`.

### Conjuntos de datos de población

Los conjuntos de datos de población proporcionan estimaciones
poblacionales en distintos niveles geográficos, para varios años y para
niños de diferentes edades. Según el nivel geográfico del análisis,
immunABC puede requerir la población correspondiente para usarla como
denominador, principalmente en los análisis de cobertura.

#### immunABC.pop.ADM0

El conjunto de datos
[`immunabc::immunABC.pop.ADM0`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM0.md)
proporciona estimaciones poblacionales agregadas a nivel nacional
(ADM0).

``` r

immunABC.pop.ADM0 %>% kable(caption = "Ejemplo de población a nivel ADM0")
```

| year | age | population |
|-----:|----:|-----------:|
| 2022 |   0 |   45846.71 |
| 2022 |   1 |   48268.88 |
| 2023 |   0 |   45445.28 |
| 2023 |   1 |   47828.03 |

Ejemplo de población a nivel ADM0 {.table}

Esta tabla está en formato largo y contiene la población (`population`)
de niños de una edad (`age`) específica durante un año (`year`)
determinado.

#### immunABC.pop.ADM1

El conjunto de datos
[`immunabc::immunABC.pop.ADM1`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM1.md)
proporciona datos poblacionales agregados al primer nivel administrativo
subnacional (ADM1), que suele corresponder a regiones, provincias o
estados.

``` r

immunABC.pop.ADM1 %>% head() %>% kable(caption = "Ejemplo de población a nivel ADM1")
```

| ADM1   | year | age | population |
|:-------|-----:|----:|-----------:|
| ADM1_1 | 2022 |   0 |   1718.189 |
| ADM1_1 | 2022 |   1 |   1808.964 |
| ADM1_1 | 2023 |   0 |   1703.145 |
| ADM1_1 | 2023 |   1 |   1792.443 |
| ADM1_2 | 2022 |   0 |   6575.261 |
| ADM1_2 | 2022 |   1 |   6922.644 |

Ejemplo de población a nivel ADM1 {.table}

Esta tabla está en formato largo y contiene la población (`population`)
de niños de una edad (`age`) específica durante un año (`year`)
determinado a nivel `ADM1`.

#### immunABC.pop.ADM2

El conjunto de datos
[`immunabc::immunABC.pop.ADM2`](https://im-data-paho.github.io/immunabc/reference/immunABC.pop.ADM2.md)
proporciona datos poblacionales más detallados por niveles ADM1 y ADM2,
lo que permite análisis con mayor desagregación geográfica.

``` r

immunABC.pop.ADM2 %>% head() %>% kable(caption = "Ejemplo de población a nivel ADM2")
```

| ADM1   | ADM2      | year | age | population |
|:-------|:----------|-----:|----:|-----------:|
| ADM1_4 | ADM2_4_29 | 2022 |   0 |   755.3488 |
| ADM1_4 | ADM2_4_29 | 2022 |   1 |   795.2554 |
| ADM1_4 | ADM2_4_26 | 2022 |   0 |   225.9325 |
| ADM1_4 | ADM2_4_26 | 2022 |   1 |   237.8689 |
| ADM1_4 | ADM2_4_27 | 2022 |   0 |   356.0747 |
| ADM1_4 | ADM2_4_27 | 2022 |   1 |   374.8869 |

Ejemplo de población a nivel ADM2 {.table}

Esta tabla está en formato largo y contiene la población (`population`)
de niños de una edad (`age`) específica durante un año (`year`)
determinado a nivel `ADM2`.

## Resumen

Todos los conjuntos de datos de ejemplo se cargan automáticamente con el
paquete. Puede explorar su estructura con `glimpse()` o
[`View()`](https://rdrr.io/r/utils/View.html). Están diseñados para
funcionar con los argumentos predeterminados de las funciones, lo que
permite probar y comprender cada módulo con una configuración mínima.

A continuación se presenta un resumen de los conjuntos de datos
disponibles para su referencia.

| Conjunto de datos   | Descripción                                           |
|---------------------|-------------------------------------------------------|
| `immunABC.EIR`      | Registro Nominal de Vacunación electrónico (RNVe)     |
| `immunABC.schedule` | Esquema de vacunación con nombres de dosis y edades   |
| `immunABC.pop.ADM0` | Estimaciones poblacionales agregadas a nivel nacional |
| `immunABC.pop.ADM1` | Estimaciones poblacionales a nivel ADM1               |
| `immunABC.pop.ADM2` | Estimaciones poblacionales a nivel ADM2               |
