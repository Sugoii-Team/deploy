FROM mcr.microsoft.com/mssql/server:2019-latest

WORKDIR /app
COPY ./FPTUBlog.sql /app

ENV ACCEPT_EULA Y
ENV sa_password Admin123
RUN sqlcmd -i FPTUBlog.sql