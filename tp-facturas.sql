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
GO

--EXEC sp_InsertarProducto @nombre = 'MAIZ' ,@precio = 34.45, @stock = 10 ,@codPais =1


CREATE PROCEDURE sp_InsertarCliente @dni int, @nombre VARCHAR(20), @apellido VARCHAR(20), @fechaNacimiento DATE, @codArea int, @numero int OUTPUT AS
INSERT INTO Clientes (Dni,Nombre,Apellido,FechaNacimiento) values (@Dni, @nombre,@apellido,@fechaNacimiento)
	BEGIN IF(@codArea is not null AND @numero is not null)
		BEGIN INSERT INTO Telefonos (Dni,CodArea,Numero)VALUES(@dni,@codArea,@numero) 
		END
	END
GO

--EXEC sp_InsertarCliente @dni =22768999 , @nombre ='Lucas' ,@apellido ='Moix' , @fechaNacimiento= '1987-11-06', @codArea =null, @numero= null
--EXEC sp_InsertarCliente @dni = 22768998, @nombre ='Marcelop' ,@apellido = 'Lopez', @fechaNacimiento= '2023-11-06', @codArea = 2281, @numero= 786932

CREATE PROCEDURE sp_VerificarStock @idProducto int  AS
BEGIN 
SELECT stock from Productos WHERE IdProducto = @idProducto;
END
GO

--EXEC sp_VerificarStock 2

CREATE PROCEDURE sp_ListarVentasXCliente @dni INT, @desde DATE, @hasta DATE 
AS
BEGIN
SELECT * FROM Ventas WHERE dni = @dni AND Fecha BETWEEN @desde AND @hasta
END
GO

--EXEC sp_ListarVentasXCliente 22768998, '2003-01-01', '2023-09-17'

--ERRORER
--creo mensaje de error
--sp_addmessage 50003, 11, "Falta Stock" 
--sp_addmessage 50004, 11, "No se puede realizar la venta"

CREATE PROCEDURE sp_InsertaDetalle
@IdVenta int,
 @IdProducto int,
 @Cantidad NUMERIC,
 @Precio NUMERIC
AS

    DECLARE @STOCK_MINIMO NUMERIC
    DECLARE @STOCK_REAL NUMERIC
    DECLARE @STOCK_DISPONIBLE NUMERIC
    DECLARE @STOCK_NUEVO NUMERIC

    SET @STOCK_MINIMO=5
    SELECT @STOCK_DISPONIBLE= (Stock -@STOCK_MINIMO), @STOCK_REAL=Stock from Productos WHERE IdProducto=@IdProducto --(EXEC sp_VerificarStock 2);
    IF(@STOCK_REAL < @STOCK_MINIMO)
        BEGIN
            RAISERROR(50003,11,1)
        END
    IF @STOCK_DISPONIBLE >= @Cantidad
        BEGIN
            INSERT INTO Detalles(IdVenta,IdProducto,Cantidad,Precio)
            values(@IdVenta,@IdProducto,@Cantidad,@Precio)
            --Actualizar Stock
            SET @STOCK_NUEVO= @STOCK_MINIMO + (@STOCK_DISPONIBLE - @Cantidad)
            UPDATE Productos SET Stock= @STOCK_NUEVO WHERE IdProducto=@IdProducto
        END
    ELSE
        BEGIN
            RAISERROR (50004, 11, 1);
        END
GO

CREATE PROCEDURE sp_InsertarVenta
@Fecha DATE, 
@dni INT
AS
BEGIN
	--INSERTO VENTA
	INSERT  Ventas (Fecha,Dni)VALUES (@Fecha, @dni);
END
GO

CREATE PROCEDURE sp_InsertarVenta_OUTPUT
@Fecha DATE, 
@dni INT,
@IdProducto int,
@Cantidad NUMERIC,
@Precio NUMERIC
OUTPUT, @error_code int OUTPUT, @error_description char(50) OUTPUT
AS
declare @IdVenta INT
		select @error_code=0;
		select @error_description='';
		select @IdVenta=-1;
		begin try
			INSERT  Ventas (Fecha,Dni)VALUES (@Fecha, @dni);
			SET @IdVenta= SCOPE_IDENTITY();
			 EXEC sp_InsertaDetalle @IdVenta,@IdProducto,@Cantidad,@Precio;
		END TRY
		BEGIN CATCH
			SET @IdVenta=-1;
			select @error_code=ERROR_NUMBER();
			select @error_description=ERROR_MESSAGE();
		END CATCH;

--creo mensaje de error
--sp_addmessage 50003, 11, "Falta Stock" 

 --DECLARE @error_code int;
 --DECLARE @error_description char(50);

 --EXEC sp_InsertarVenta_OUTPUT '2023-09-15',22768998,2,5,20.10 , @error_code OUTPUT, @error_description OUTPUT
 --PRINT '1.ErrorCode='+str(@error_code)+ '  ERROR_DESCRIPTION='+@error_description;
GO

CREATE PROCEDURE sp_ActualizaPrecios
@FactorAumento NUMERIC(9,2)
as
BEGIN
	UPDATE Productos SET Precio= (SELECT CAST(L2.Precio+(L2.Precio *@FactorAumento) AS DECIMAL(18,2))FROM Productos L2 WHERE L2.IdProducto=Productos.IdProducto )
END
GO

--exec sp_ActualizaPrecios 0.15

CREATE PROCEDURE sp_ObtenerProductosPorPais
@CodPais int
AS
BEGIN
	SELECT A.IdProducto,A.Nombre,A.CodPais,B.DescPais
	FROM Productos A INNER JOIN Paises B
	ON A.CodPais=B.CodPais
	WHERE A.CodPais=@CodPais
END
GO

-- sp_ObtenerProductosPorPais 2

CREATE PROCEDURE sp_BorrarTelefono
@NroTelefono INT
AS

IF (SELECT COUNT(1)TOTAL FROM Telefonos WHERE DNI IN(SELECT DNI FROM Telefonos WHERE Numero=@NroTelefono))>1
	BEGIN
		DELETE FROM Telefonos WHERE Numero=@NroTelefono
	END
ELSE
	BEGIN
	RAISERROR('No se puede Borrar',16,1)
	END
GO