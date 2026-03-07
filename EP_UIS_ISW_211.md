# UNIVERSIDAD INDUSTRIAL DE SANTANDER
## PRIMER EXAMEN PARCIAL — Ingeniería de Sistemas
**Mejores Prácticas de Ingeniería de Software**
*Jeison Mauricio Delgado González – Ingeniero De Sistemas*

---

NOMBRE COMPLETO: _______________________________________________

CÓDIGO DE ESTUDIANTE: ____________________________________________

> *"En el mundo de la ingeniería de software, cada línea de código es una oportunidad para cambiar el mundo"*

---

## Resumen Know How

### ¿Qué es el know how empresarial?

El término *know how* se puede considerar como un activo intangible de la empresa. Es un término que puede aplicarse tanto a la parte estratégica como a la parte operativa y técnica de la organización, y en definitiva agrupa los conocimientos que se extienden a toda la compañía y que la han llevado al éxito.

> *"No es más que un conjunto de experiencias que han llevado al éxito y ahora conforman el saber hacer de la empresa"*

A la hora de medirlo, hay que hacerlo en términos económicos, pues este saber hacer o saber cómo incide en la posición de la compañía respecto a la competencia. Esto da como resultado una *ventaja competitiva* de la que se hablará más adelante.

---

### ¿Cómo saber si hay un know how en la organización?

Muchas veces se tiende a usar este término de manera incorrecta para definir cualquier proceso utilizado en una compañía. Sin embargo, hay ciertos requisitos que deben cumplirse para hablar de know how de manera correcta.

#### ¿Es concreto?

El primero de ellos es que debe ser algo concreto: una determinada técnica, un ingrediente específico… hay muchas posibilidades. No se puede hablar de know how para decir que una compañía trabaja solo con materiales de calidad, por ejemplo. Esto sería hablar de ética o visión, pero es algo muy general y que puede decir cualquier otra organización, por lo que no se podría considerar que esté dentro de este saber hacer.

#### ¿Es secreto?

Por otro lado, debe tratarse de algo secreto. Es decir, no es know how una técnica que usan todas las empresas del sector, solo lo será si precisamente es un rasgo que distingue a la compañía de la competencia. De hecho, este conocimiento puede protegerse legalmente.

> "Las personas físicas y jurídicas tendrán la posibilidad de impedir que la información que esté legítimamente bajo su control se divulgue a terceros o sea adquirida o utilizada por terceros sin su consentimiento, de manera contraria a los usos comerciales honestos"

#### ¿Otorga una ventaja competitiva?

El saber cómo ha de otorgar una ventaja competitiva. Esto es un lugar destacado y privilegiado respecto a otras empresas con motivo de este aspecto característico. Por eso mismo debería poder valorarse desde el punto de vista económico.

*En definitiva, no se puede considerar know how cualquier técnica utilizada en una compañía. Solo lo será si es concreta y exclusiva, ajena a la competencia.*

#### ¿Cómo transmitir el know how?

Se puede elaborar un manual que lean los nuevos empleados, pero puede haber dudas que queden sin resolver, por lo que habría que combinarlo con otras técnicas. Una de ellas es asignar un mentor que acompañe al trabajador en su proceso de adaptación a la empresa. Se ocupará de explicarle todo lo que tiene que saber y de supervisar lo que hace hasta que lo vea preparado para trabajar solo.

La rotación de puestos es también muy útil para este objetivo. Consiste en que el empleado vaya pasando por distintos departamentos para que vaya conociendo el funcionamiento global de la empresa.

---

## Desarrollo de Proyectos de Software

### 1. Descripción de la Actividad

En el marco de su formación como Ingeniero de Software, usted deberá desarrollar un **proyecto de software** basado en el **Decálogo de Fundamentos de Gerencia**. La actividad se enfoca en diseñar y estructurar una propuesta de negocio, teniendo en cuenta factores como la planificación, validación y posicionamiento de la marca en el mercado.

### 2. Objetivos

- Desarrollar un proyecto de software con una base gerencial sólida.
- Definir los aspectos clave de la empresa: **nombre, logotipo, eslogan, presupuesto y plan de ejecución.**
- Establecer una planificación estratégica y operativa para el desarrollo del producto.
- Analizar la competencia y realizar un pronóstico de crecimiento a corto, mediano y largo plazo.
- Presentar el proyecto de manera profesional a un equipo evaluador.

### 3. Selección del Proyecto

#### DESARROLLO DE APP PARA MICROEMPRESAS

Solicitamos el desarrollo de una **aplicación móvil** diseñada especialmente para MICROEMPRESAS, que permita controlar de manera sencilla y eficiente los ingresos, gastos e inventarios de esta.

---

### Estructura de la Aplicación

La pantalla principal deberá contener 5 iconos los cuales se explicarán a continuación:

#### 1. INGRESOS
*(Los ingresos son todas las entradas de dinero o recursos económicos que recibe una persona o empresa como resultado de su actividad)*

Se solicita que la aplicación contenga:
- Registro diario de ventas en (efectivo, crédito, transferencia o tarjeta)
- Registro de abonos de clientes.
- Reporte diario, semanal y mensual.

#### 2. COMPRAS
*(Las compras son las adquisiciones de bienes o mercancías que hace un negocio para venderlas)*

Se solicita que la aplicación contenga:
- Registro diario de compras en (efectivo, crédito, transferencia o tarjeta)
- Registro de pagos a proveedores.
- Reporte diario, semanal y mensual.

#### 3. GASTOS
*(Un gasto es un desembolso de dinero que hace un negocio para poder funcionar, pero que no se convierte en inventario ni en un activo para vender)*

Se solicita que la aplicación contenga:
- Registro diario de gastos en (efectivo, crédito, transferencia o tarjeta)
- Registro de pagos de gastos.
- Reporte diario, semanal y mensual.

#### 4. CONTROL DE INVENTARIOS
*(El inventario es el conjunto de productos o mercancías que tiene un negocio disponible para la venta)*

Se solicita que la aplicación contenga:
- Registro de inventario manual (para inventario inicial o inventario sin factura)
- El registro de las compras deberá integrarse automáticamente con el módulo de inventarios, actualizando las existencias en tiempo real (ingreso de productos al stock).
- Cada venta registrada impactará automáticamente el módulo de inventarios, reflejando en tiempo real la salida de los productos vendidos que disminuye el stock.
- Alertas de bajo stock.
- Control de productos próximos a vencer.

#### 5. REPORTES
*(Los reportes son informes organizados que muestran información del negocio de forma clara y resumida, para ayudar a tomar decisiones)*

**Flujo de Caja** *(muestra el dinero que entra y el dinero que sale del negocio en un período determinado: día, semana o mes)*

Estructura:
```
+ Ingresos recibidos en efectivo
- Compras pagadas en efectivo
- Gastos pagadas en efectivo
= Total en la Caja
```

**Reporte de Cuentas por Cobrar** *(valores que los clientes le deben al negocio por ventas realizadas a crédito)*
Se solicita emitir un informe de los clientes que me deben a la fecha de emisión del reporte.

**Reporte de Cuentas por Pagar** *(deudas que el negocio tiene con proveedores u otras personas por compras o servicios recibidos que aún no se han pagado)*
Se solicita emitir un informe de lo que debemos tanto en compras y gastos a la fecha de emisión.

**Estado de Resultado** *(reporte financiero que muestra si un negocio tuvo utilidad o pérdida en un período determinado: día, mes o año)*

Estructura:
```
+ Total Ingresos (Contado y Crédito)
- Total Costo (Contado y Crédito)
- Total Gastos (Contado y Crédito)
= Utilidad o Pérdida
```

---

### Hechos Económicos

#### COMPRAS

| CÓDIGO | NOMBRE | CANTIDAD | PRECIO | FORMA DE PAGO |
|--------|--------|----------|--------|---------------|
| 001 | Café Volcán en granos 250gr | 100 | $11.460 | Efectivo |
| 002 | Café Finca en grano 454gr | 150 | $45.780 | Nequi |
| 003 | Café Mujeres Cafeteras en granos 454gr | 200 | $45.780 | Nequí |
| 004 | Café Origen Nariño en granos 454gr | 250 | $45.780 | Crédito |
| 005 | Café Colina en grano 454gr | 300 | $36.650 | Crédito |

#### GASTOS

| DESCRIPCIÓN | PRECIO | FORMA DE PAGO |
|-------------|--------|---------------|
| Agua | $100.000 | Nequi |
| Luz | $70.000 | Nequi |
| Internet | $150.000 | Nequi |
| Nómina | $2.000.000 | Nequi |
| Seguridad Social | $500.000 | Nequi |
| Arriendo | $2.000.000 | Nequi |
| Útiles de Aseo | $50.000 | Nequi |
| Vigilancia | $70.000 | Nequi |

#### VENTAS

| CÓDIGO | NOMBRE | CANTIDAD | PRECIO | FORMA DE PAGO |
|--------|--------|----------|--------|---------------|
| 001 | Café Volcán en granos 250gr | 50 | $31.460 | Efectivo |
| 002 | Café Finca en grano 454gr | 100 | $65.780 | Nequi |
| 003 | Café Mujeres Cafeteras en granos 454gr | 150 | $65.780 | Nequi |
| 004 | Café Origen Nariño en granos 454gr | 200 | $65.780 | Nequi |
| 005 | Café Colina en grano 454gr | 250 | $56.650 | Crédito |

#### COSTO DE VENTA

| CÓDIGO | NOMBRE | CANTIDAD | PRECIO | FORMA DE PAGO |
|--------|--------|----------|--------|---------------|
| 001 | Café Volcán en granos 250gr | 50 | $11.460 | Efectivo |
| 002 | Café Finca en grano 454gr | 100 | $45.780 | Nequi |
| 003 | Café Mujeres Cafeteras en granos 454gr | 150 | $45.780 | Nequi |
| 004 | Café Origen Nariño en granos 454gr | 200 | $45.780 | Nequi |
| 005 | Café Colina en grano 454gr | 250 | $36.650 | Crédito |

*Agradecemos la aplicación de su conocimiento para la mejora continua de procesos que aportan orientación y crecimiento en el pequeño empresario.*

---

### 4. Planificación del Proyecto

Complete la siguiente tabla con los datos de su propuesta de software:

| Elemento | Descripción |
|----------|-------------|
| Nombre del Proyecto | |
| Logotipo | *(Incluir imagen o descripción)* |
| Eslogan | |
| Presupuesto Estimado | *(Detallar costos de desarrollo, marketing, etc.)* |
| Integrantes del Equipo | *(Roles y responsabilidades)* |
| Actividades Clave | *(Check-list para registrar la empresa y la marca)* |

---

### 5. Estrategia de Posicionamiento y Evaluación de Mercado

Complete la siguiente tabla considerando el posicionamiento de su marca y la competencia en el mercado:

| Aspecto | Descripción |
|---------|-------------|
| Competidores Directos | *(Empresas con productos similares)* |
| Competidores Indirectos | *(Alternativas en el mercado)* |
| Proyección de Crecimiento (1, 3 y 5 años) | *(Análisis y pronóstico de expansión)* |
| Factores Diferenciadores | *(¿Qué hace única su propuesta?)* |
| Aplicación del "Know How" | *(Conocimientos y experiencia como ventaja competitiva)* |

---

