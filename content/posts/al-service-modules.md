+++
author = "Luis Michael Ibarra"
title = "Golang Modules"
date = "2022-04-23"
tags = [
    "golang",
    "modules",
    "mirror",
    "mvs",
]
+++


_go modules_ ayuda a manejar tus dependencias de golang.

## Proyecto

Es un repositorio de código. Algunas veces estos proyectos pueden contener paquetes 
que ayudan a construir otros programas. Otras veces son aplicaciones que producen
un binario. Un proyecto puede manejar más de una aplicación o más de un paquete.

El proyecto ayuda a definir el diseño, estándares y consistencia del proyecto para 
todo el equipo lo cual implica que todos los miembros sigan los mismos objetivos. 
De la misma manera, tener más de un proyecto incurre en la probabilidad de que 
los estándares sean diferentes.

## Inicialización

Permite inicializar un proyecto de golang definiendo donde se encuentra su raíz.

    $go mod init <name> #inicializa un proyecto en un namespace
    $go mod init github.com/clvx/golang-lab #convención es utilizar url para el nombre

_go mod init_ crea el archivo _go.mod_ que indica a las herramientas de golang 
que éste es un proyecto de golang que utiliza go modules donde específica el nombre 
y directorio raíz del proyecto. Debería haber un solo `go.mod` por proyecto; sin 
embargo, si se mantienen varios servicios se puede utilizar directorios donde cada 
uno tiene su propio `go.mod` en vez de crear un proyecto (alias repositorio) para 
cada uno de los servicios.

    $cat go.mod
    module github.com/clvx/golang-lab

    go 1.18

La versión de go en _go.mod_ refiere a que el proyecto es compatible con versiones 
mayor o igual a _1.18_ pero no con versiones inferiores a `1.18`.

## Obteniendo dependencias

Las dependencias de un proyecto go son descargadas en el directorio cache definido 
en la variable de entorno `GOMODCACHE` para poder compilar el proyecto.
    
    $cat main.go
    package main

    import (
        "github.com/clvx/conf"
    )

    func main() {
        conf.New() #crea un error
    }

    $go mod tidy #descargando dependencias

    $go env GOMODCACHE
    /home/clvx/go/pkg/mod

    $ls $(go env GOMODCACHE) #listando las dependencias localmente
    github.com/clvx/conf

`gopls` utiliza `GOMODCACHE` para habilitar IntelliSense en dependencias.

### go mod tidy

`go mod tidy` verifica las dependencias del paquete, busca cada una las dependencias 
de acuerdo a `GOPROXY`, devuelve las versiones vigentes, y realiza una petición 
para obtener la versión más apropiada para compilar la aplicación, el servidor 
retorna un archivo comprimido zip con el código que se descarga y descomprime
en `$(go env GOMODCACHE)`. Luego, modifica `go.mod` actualizando las dependencias 
con sus versiones y actualiza `go.sum` añadiendo un hash basado en `go.mod` y otro 
basado en `go.sum` y `go.mod` verificándolos con la _Checksum DB_ que mantiene 
Google si no existieran. 

    $go mod GOPROXY
    https://proxy.golang.org,direct

    $cat go.mod
    module github.com/clvx/golang-lab

    go 1.18

    require github.com/clvx/conf v1.0

    $cat go.sum
    github.com/clvx/conf v1.0 h1:<hash_value>
    github.com/clvx/conf v1.0/go.mod h1:<hash_value>

La variable de entorno `GOPROXY` indica el lugar de descarga del código fuente 
de las dependencias. Por defecto `GOPROXY` utiliza los servidores de google como
el proxy por defecto. El servidor proxy funciona buscando en su base de datos si 
existe el paquete con la versión apropiada para descargar, si no existe, se conecta 
con el repositorio fuente (e.j. `github.com/clvx/conf`) y obtiene un snapshot de 
ese paquete y lo guarda en su base de datos, luego retorna la respuesta con el 
paquete comprimido a `go mod tidy`. Si existiera el paquete, retorna la respuesta 
con el paquete comprimido a `go mod tidy`.

Sin embargo, la opción `direct` de `GOPROXY` sirve para casos donde se utiliza 
VCS privados donde el proxy de google no tiene acceso. Además, si se require
evitar el proxy de google completamente, se puede definir la la variable de entorno 
`GONOPROXY` con los dominios que se quieren evitar.

    $export GONOPROXY="github.com" #set GONOPROXY

    $go env GONOPROXY
    github.com

    $unset GONOPROXY #unsets GONOPROXY

### Vendor

`go mod vendor` permite includir las dependencias definidas en `go.mod` que han 
sido descargadas en `GOMODCACHE` dentro del proyecto en el directorio `vendor/`.
Vendoring es importante para compilar tu proyecto en case las dependencias no 
se pueden acceder por cualquier razón.

    go mod vendor

### Minimal Version Selection - MVS

When installing or updating dependencies, [Minimal Version Selection](https://research.swtch.com/vgo-mvs) 
always selects the minimal (oldest) module version that satisfies the overall 
requirements of a build.

### Athens

[Athens](https://gomods.io/) es un servidor proxy open source para desplegar en tus
propios entornos. Para poder utilizar _Athens_ se modifica `GOPROXY` apuntando al 
servidor proxy local. _Athens_ también permite conectarse al servidor proxy de 
Google o configurarlo para conectarse a las diferentes fuentes sin pasar por 
Google. Es una buena manera para manejar tus dependencias localmente o aumentar 
tu privacidad.


