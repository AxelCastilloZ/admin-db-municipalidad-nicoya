-- =============================================
-- CREACIÓN DE BASE DE DATOS DATAMART
-- Base de datos separada para el Data Mart
-- =============================================

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MunicipalidadNicoyaDataMart')
BEGIN
    ALTER DATABASE MunicipalidadNicoyaDataMart SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MunicipalidadNicoyaDataMart;
END
GO

CREATE DATABASE MunicipalidadNicoyaDataMart
ON PRIMARY 
(
    NAME = 'MunicipalidadNicoyaDataMart_Data',
    FILENAME = 'C:\SQLData\MunicipalidadNicoyaDataMart_Data.mdf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 50MB
)
LOG ON 
(
    NAME = 'MunicipalidadNicoyaDataMart_Log',
    FILENAME = 'C:\SQLData\MunicipalidadNicoyaDataMart_Log.ldf',
    SIZE = 50MB,
    MAXSIZE = 500MB,
    FILEGROWTH = 25MB
);
GO

ALTER DATABASE MunicipalidadNicoyaDataMart SET RECOVERY SIMPLE;
ALTER DATABASE MunicipalidadNicoyaDataMart SET AUTO_SHRINK OFF;
ALTER DATABASE MunicipalidadNicoyaDataMart SET AUTO_UPDATE_STATISTICS ON;
GO

USE MunicipalidadNicoyaDataMart;
GO