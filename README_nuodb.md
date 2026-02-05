# NuoDB initial attempt of enabling Keycloak for NuoDB access

# Development setup
- clone https://github.com/agoelzer/keycloak
- clone nuodb sources next to the keycloak sources, i.e.
  /home/user/workspace/keycloak
  /home/user/workspace/nuodb
- optionally clone liquibase https://github.com/liquibase/liquibase
- build and package nuodb sources
- "cd" into to keycloak source directory
- run "./buildrun.sh start_nuodb"
- run "./buildrun.sh buildKeycloak extractArchive runLocal"

## For debug mode (remote Java debugging):
- run "./buildrun.sh buildKeycloak extractArchive runDebug"
- attach to port "5005" twice (first time is just config updates before it launches keycloak)

## Current state
Many of the tables are created but there is still a lot which needs to be done for the schema to work.

Several source files are created in the keycloak source base:
- additional classes for NuoDB support
- copies of liquibase source classes which had to be modified. Instead of creating another liquibase project, I just copied the necessary classes to the keycloak codebase (which will overwrite the liquibase library ones).
