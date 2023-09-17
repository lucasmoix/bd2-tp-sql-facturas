--SE CREAN LAS TABLAS

CREATE TABLE Paises(
CodPais INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
DescPais VARCHAR(50)
)
GO
-- INSERT INTO Paises(DescPais)VALUES('Argentina'),('Brasil'),('Uruguay')

CREATE TABLE Productos(
IdProducto INT IDENTITY (1,1) PRIMARY KEY NOT NULL,
Nombre VARCHAR(50) NOT NULL,
Precio MONEY NOT NULL,
Stock numeric(9,2) NOT NULL DEFAULT 0,
CodPais int NOT NULL,
FOREIGN KEY (CodPais) REFERENCES Paises(CodPais) 
)
GO
-- INSERT  Productos(Nombre,Precio,Stock,CodPais)VALUES('MAIZ',34.45,10,1),('HARINA',56.45,9,2),('POROTOS',20,30,3)

CREATE TABLE Clientes(
Dni INT PRIMARY KEY NOT NULL,
Nombre VARCHAR(20) NOT NULL,
Apellido VARCHAR(20) NOT NULL,
FechaNacimiento DATE NOT NULL
)
GO
-- INSERT Clientes(Dni,Nombre,Apellido,FechaNacimiento)VALUES(22768999,'Moix','Lucas','1987-11-06'),(22768998,'Lopez','Marcelop','2023-11-06')
--select * from Clientes

CREATE TABLE Telefonos(
Dni INT NOT NULL,   
CodArea int NOT NULL,
Numero int NOT NULL,
FOREIGN KEY (Dni) REFERENCES Clientes(Dni)
)
GO
CREATE UNIQUE INDEX index_telefon
 ON telefonos (Dni,CodArea,numero)
-- INSERT Telefonos(Dni,CodArea,Numero)VALUES(22768999,11,45678987),(22768998,11,8799988),(22768998,2281,786932)

CREATE TABLE Ventas(
IdVenta INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
Fecha DATE not NULL,
Dni INT NOT NULL,
FOREIGN KEY (Dni) REFERENCES Clientes(Dni),
)
GO
--insert Ventas (Fecha,Dni) values (getdate(),22768998)
--insert Ventas (Fecha,Dni) values ('2003-03-01',22768998)
--insert Ventas (Fecha,Dni) values ('2025-01-01',22768998)


CREATE TABLE Detalles(
IdDetalle INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
IdVenta INT,
IdProducto INT,
Cantidad NUMERIC(9,2),
Precio NUMERIC(9,2),
FOREIGN KEY (IdVenta) REFERENCES Ventas(IdVenta),
FOREIGN KEY (idProducto) REFERENCES Productos(IdProducto)
)
GO


--SE CREAN LOS STORES PROCEDURES
CREATE PROCEDURE sp_InsertarProducto @nombre VARCHAR(50), @precio numeric, @stock numeric, @codPais int OUTPUT 
AS
BEGIN
INSERT INTO Productos (Nombre,Precio,Stock,CodPais) values (@nombre,@precio,@stock,@codPais )
END


--EXEC sp_InsertarProducto @nombre = 'MAIZ' ,@precio = 34.45, @stock = 10 ,@codPais =1
GO

CREATE PROCEDURE sp_InsertarCliente @dni int, @nombre VARCHAR(20), @apellido VARCHAR(20), @fechaNacimiento DATE, @codArea int, @numero int OUTPUT AS
INSERT INTO Clientes (Dni,Nombre,Apellido,FechaNacimiento) values (@Dni, @nombre,@apellido,@fechaNacimiento)
	BEGIN IF(@codArea is not null AND @numero is not null)
		BEGIN INSERT INTO Telefonos (Dni,CodArea,Numero)VALUES(@dni,@codArea,@numero) 
		END
	END


--EXEC sp_InsertarCliente @dni =22768999 , @nombre ='Lucas' ,@apellido ='Moix' , @fechaNacimiento= '1987-11-06', @codArea =null, @numero= null
--EXEC sp_InsertarCliente @dni = 22768998, @nombre ='Marcelop' ,@apellido = 'Lopez', @fechaNacimiento= '2023-11-06', @codArea = 2281, @numero= 786932
GO

CREATE PROCEDURE sp_VerificarStock @idProducto int  AS
BEGIN 
SELECT stock from Productos WHERE IdProducto = @idProducto;
END

--EXEC sp_VerificarStock 2
GO

CREATE PROCEDURE sp_ListarVentasXCliente @dni INT, @desde DATE, @hasta DATE 
AS
BEGIN
SELECT * FROM Ventas WHERE dni = @dni AND Fecha BETWEEN @desde AND @hasta
END

--EXEC sp_ListarVentasXCliente 22768998, '2003-01-01', '2023-09-17'
GO

CREATE PROCEDURE sp_InsertarVenta @Fecha DATE, @dni INT
AS
BEGIN
INSERT  Ventas VALUES (@Fecha, @dni)
END

--EXEC sp_InsertarVenta @Fecha = '2023-09-17', @dni = 22768998
GO
