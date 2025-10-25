USE master;
GO

CREATE DATABASE MunicipalidadNicoya
ON PRIMARY 
(
    NAME = 'MunicipalidadNicoya_Data',
    FILENAME = 'C:\SQLData\MunicipalidadNicoya_Data.mdf',
    SIZE = 100MB,           
    MAXSIZE = 500MB,        
    FILEGROWTH = 10MB       
)
LOG ON
(
    NAME = 'MunicipalidadNicoya_Log',
    FILENAME = 'C:\SQLData\MunicipalidadNicoya_Log.ldf',
    SIZE = 50MB,            
    MAXSIZE = 200MB,       
    FILEGROWTH = 10MB       
);
GO

USE MunicipalidadNicoya;
GO