# BLauncher - Minecraft Version Manager

BLauncher is a Batch-based Minecraft installation manager written by CLDevs.

## Features

* Save and load local profiles
* List installed versions
* Download version metadata
* Download required game resources
* Organize installations by version
* Launch locally installed Java applications

## Minecraft Installation Structure

Each Minecraft version consists of several components.

### Version Manifest

The global manifest contains every available version and metadata URLs.

File:

```text
manifest.json
```

Contains:

* Version IDs
* Release types
* Metadata URLs

---

### Version Metadata

Each version has its own metadata JSON.

Example:

```text
versions/1.21.11-rc2/1.21.11-rc2.json
```

Contains:

* Client download information
* Asset index information
* Required libraries
* Java version requirements
* JVM arguments

---

### Client JAR

The client JAR contains the game's compiled Java code.

Example:

```text
versions/1.21.11-rc2/client.jar
```

---

### Libraries

Minecraft depends on many Java libraries.

Example structure:

```text
libraries/
├── com/
├── org/
└── net/
```

Examples include:

* LWJGL
* Log4j
* Guava
* Gson

---

### Assets

Assets include:

* Textures
* Sounds
* Language files
* Models

Example:

```text
assets/
├── indexes/
└── objects/
```

---

### Java Runtime

Minecraft requires Java.

Examples:

* Java 8
* Java 17
* Java 21

The required version is specified inside the version metadata.

## Project Goal

BLauncher demonstrates how Minecraft installations are organized and managed locally using Batch scripts and PowerShell.
