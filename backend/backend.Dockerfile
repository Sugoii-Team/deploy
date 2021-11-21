FROM maven:3.8.3-eclipse-temurin-11

# Build my project
WORKDIR /app
RUN git clone https://github.com/Sugoii-Team/fptublog-backend.git /app

EXPOSE 8080
CMD mvn -f pom.xml tomcat9:run