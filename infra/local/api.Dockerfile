FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY api/pom.xml .
RUN mvn -q dependency:go-offline
COPY api/src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:17-jre
RUN useradd --create-home appuser
COPY --from=build /src/target/surplus-food-*.jar /srv/app.jar
USER appuser
CMD ["java", "-jar", "/srv/app.jar"]
