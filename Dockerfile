# syntax=docker/dockerfile:1

# Entorno base, descarga las dependencias y copia el codigo fuente
# a la carpeta de trabajo de la imagen eclipse-temurin:17-jdk-jammy
FROM eclipse-temurin:17-jdk-jammy as base
WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
# Este comando descarga las dependencias encontradas en el pom.xml
RUN ./mvnw dependency:resolve
# Copiamos el codigo fuente
COPY src ./src

# Para testing
FROM base as test
RUN ["./mvnw", "test"]

# El entorno de desarrollo ejecuta el entorno base y corre la aplicacion con el comando del spring boot maven plugin
# pring-boot:run -Dspring-boot.run.profiles=mysql -Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'
FROM base as development
CMD ["./mvnw", "spring-boot:run", "-Dspring-boot.run.profiles=mysql", "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

# El perfil build, genera el jar o war
FROM base as build
RUN ./mvnw package

# El perfil de produccion copia el jar hacia la imagen y la ejecuta, en el perfil de produccion
# no es necesario que se tenga el codigo fuente
FROM eclipse-temurin:17-jre-jammy as production
EXPOSE 8080
COPY --from=build /app/target/spring-petclinic-*.jar /spring-petclinic.jar
CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/spring-petclinic.jar"]

