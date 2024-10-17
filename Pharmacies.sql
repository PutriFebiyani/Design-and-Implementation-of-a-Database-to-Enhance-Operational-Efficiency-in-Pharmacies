-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 05, 2023 at 01:09 PM
-- Server version: 10.4.28-MariaDB
-- PHP Version: 8.0.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `apoteksehat`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `BiggestTransaction_ByMonth` (IN `bulan` INT, OUT `namaBulan` VARCHAR(15), OUT `nama` VARCHAR(50), OUT `transaksi` INT)   BEGIN
    DECLARE tempNamaBulan VARCHAR(15);
    DECLARE tempNama VARCHAR(50);
    DECLARE tempTransaksi INT;

    SELECT MONTHNAME(TH.transactionDate), C.customerName, SUM(O.hargaJual * TD.jumlahBeli)
    INTO tempNamaBulan, tempNama, tempTransaksi
    FROM transactionheader AS TH
    INNER JOIN mscustomer AS C ON C.customerID = TH.customerID
    INNER JOIN transactiondetail AS TD ON TH.transactionID = TD.transactionID
    INNER JOIN msobat AS O ON O.obatID = TD.obatID
    WHERE MONTH(TH.transactionDate) = bulan
    GROUP BY TH.transactionDate, C.customerName
    ORDER BY SUM(O.hargaJual * TD.jumlahBeli) DESC
    LIMIT 1;

    SET namaBulan = tempNamaBulan;
    SET nama = tempNama;
    SET transaksi = tempTransaksi;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Calculate_Income_ByMonth` (IN `tahun` YEAR)   BEGIN
    SELECT MONTHNAME(TH.transactionDate) AS Month, 
    SUM(O.hargaJual * TD.jumlahBeli) - SUM(O.hargaBeli * TD.jumlahBeli) AS Income
    FROM transactiondetail AS TD
    INNER JOIN msobat AS O ON O.obatID = TD.obatID
    INNER JOIN transactionheader AS TH ON TH.transactionID = TD.transactionID
    WHERE YEAR(TH.transactionDate) = tahun
    GROUP BY MONTHNAME(TH.transactionDate)
    ORDER BY MONTH(TH.transactionDate);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Insert_MsCustomer` (IN `c_id` CHARACTER(5), IN `c_name` VARCHAR(50), IN `c_phone` VARCHAR(14), `c_DOB` DATE)   BEGIN
	INSERT INTO mscustomer(customerID, customerName, customerPhone, customerDOB) VALUES(c_id, c_name, c_phone, c_DOB);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Insert_MsObat` (IN `o_id` CHARACTER(6), IN `p_id` CHARACTER(5), IN `hargaBeli` INT, IN `o_name` VARCHAR(50), IN `stock` INT, IN `hargaJual` INT, IN `exp` DATE, IN `jenis` VARCHAR(30), IN `satuan` VARCHAR(20), `deskripsi` VARCHAR(70))   BEGIN
	INSERT INTO msobat(obatID, produsenID, hargaBeli, obatName, obatStock, hargaJual, expDate, jenisObat, satuan, deskripsiObat) VALUES(o_id, p_id, hargaBeli, o_name, stock, hargaJual, exp, jenis, satuan, deskripsi);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Search_Transaction_ByID` (IN `transID` CHAR(5), OUT `name` VARCHAR(50), OUT `phone` VARCHAR(50), OUT `list_obat` VARCHAR(100), OUT `totalBayar` INT)   BEGIN
    SELECT C.customerName INTO name
    FROM mscustomer AS C
    INNER JOIN transactionheader AS TH ON C.customerID = TH.customerID
    WHERE TH.transactionID = transID;
    
    SELECT C.customerPhone INTO phone
    FROM mscustomer AS C
    INNER JOIN transactionheader AS TH ON C.customerID = TH.customerID
    WHERE TH.transactionID = transID;

    SELECT GROUP_CONCAT(O.obatName SEPARATOR ',') INTO list_obat
    FROM transactiondetail AS TD
    INNER JOIN msobat AS O ON TD.obatID = O.obatID
    GROUP BY TD.transactionID
    HAVING TD.transactionID = transID;

    SELECT SUM(O.hargaJual * TD.jumlahBeli) INTO totalBayar
    FROM transactiondetail AS TD
    INNER JOIN msobat AS O ON O.obatID = TD.obatID
    WHERE TD.transactionID = transID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_AddStock` (IN `o_id` CHARACTER(6), IN `addInput` INT)   BEGIN
	UPDATE msobat AS O
    SET O.obatStock = O.obatStock + addInput
    WHERE O.obatID = o_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Update_Stock` ()   BEGIN
	UPDATE msobat AS O
    INNER JOIN transactiondetail AS TD
    ON TD.obatID = O.obatID
    INNER JOIN transactionheader AS TH
    ON TH.transactionID = TD.transactionID
    SET O.obatStock = O.obatStock - TD.jumlahBeli
    WHERE TH.transactionDate = CURDATE();
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `Calculate_Income` () RETURNS INT(11)  BEGIN
	DECLARE totalJual INT;
    DECLARE totalBeli INT;
    DECLARE income INT;
    
	SELECT SUM(O.hargaJual*TD.jumlahBeli) INTO totalJual
    FROM transactiondetail AS TD
    INNER JOIN msobat AS O
    ON O.obatID=TD.obatID
    INNER JOIN transactionheader AS TH
    ON TH.transactionID = TD.transactionID;
    
    SELECT SUM(O.hargaBeli*TD.jumlahBeli) INTO totalBeli
    FROM transactiondetail AS TD
    INNER JOIN msobat AS O
    ON O.obatID=TD.obatID
    INNER JOIN transactionheader AS TH
    ON TH.transactionID = TD.transactionID;

    
    SET income = totalJual-totalBeli;
    
    RETURN income;
    
    END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `informasi_produsen`
-- (See below for the actual view)
--
CREATE TABLE `informasi_produsen` (
`produsenName` varchar(50)
,`produsenPhone` varchar(14)
,`produsenAddress` varchar(70)
,`Nama Obat` mediumtext
);

-- --------------------------------------------------------

--
-- Table structure for table `mscustomer`
--

CREATE TABLE `mscustomer` (
  `customerID` char(5) NOT NULL,
  `customerName` varchar(50) NOT NULL,
  `customerPhone` varchar(14) NOT NULL,
  `customerDOB` date NOT NULL CHECK (octet_length(`customerPhone`) between 12 and 14 and substr(`customerPhone`,1,2) = '62' and `customerPhone` regexp '^[0-9]+$' and `customerID` regexp '^CU[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `mscustomer`
--

INSERT INTO `mscustomer` (`customerID`, `customerName`, `customerPhone`, `customerDOB`) VALUES
('CU001', 'Budi Santoso', '6281334455678', '1990-05-15'),
('CU002', 'Gina Hermawan', '6289876543210', '1997-01-10'),
('CU003', 'William Tan', '6285678901234', '1999-02-14'),
('CU004', 'Putri Febiyani', '6282345678901', '2004-02-10'),
('CU005', 'Regina Celine', '6283456789012', '2004-06-09'),
('CU006', 'Nazhira Dewi', '6281112345678', '2005-01-11'),
('CU007', 'Sean Putra', '6288887654321', '2001-01-05'),
('CU008', 'Andrew Manurung', '6287771234567', '2002-08-14'),
('CU009', 'Sangkara Pratama', '6289998765432', '2002-12-31'),
('CU010', 'Asad Alkatiri', '6286669876543', '2004-01-28'),
('CU011', 'Budi Utomo', '621231231322', '2004-02-13'),
('CU012', 'Stefani Maia', '628398474747', '2000-03-30'),
('CU013', 'Karina Aespa', '6287836463743', '2000-08-15');

-- --------------------------------------------------------

--
-- Table structure for table `msobat`
--

CREATE TABLE `msobat` (
  `obatID` char(6) NOT NULL,
  `produsenID` char(5) NOT NULL,
  `hargaBeli` int(11) NOT NULL,
  `obatName` varchar(50) NOT NULL,
  `obatStock` int(11) NOT NULL,
  `hargaJual` int(11) NOT NULL,
  `expDate` date NOT NULL,
  `jenisObat` varchar(30) NOT NULL,
  `satuan` varchar(20) NOT NULL,
  `deskripsiObat` varchar(70) NOT NULL CHECK (`obatID` regexp '^MED[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `msobat`
--

INSERT INTO `msobat` (`obatID`, `produsenID`, `hargaBeli`, `obatName`, `obatStock`, `hargaJual`, `expDate`, `jenisObat`, `satuan`, `deskripsiObat`) VALUES
('MED001', 'PR001', 3500, 'Oskadon', 33, 6000, '2025-05-18', 'Tablet', '300 g', 'Menyembuhkan sakit kepala dan pegal-pegal'),
('MED002', 'PR001', 12000, 'Paramex', 50, 15000, '2024-12-15', 'Tablet', '250 g', 'Menyembuhkan sakit kepala'),
('MED003', 'PR001', 4000, 'Antangin', 40, 8000, '2026-02-24', 'Tablet', '350 g', 'Menyembuhkan masuk angin'),
('MED004', 'PR002', 1500, 'Tolak Angin', 60, 3000, '2025-01-08', 'Sirup', '15 ml', 'Menyembuhkan masuk angin'),
('MED005', 'PR002', 20000, 'Oralit', 35, 25000, '2025-05-18', 'Sirup', '200 ml', 'Menggantikan cairan tubuh saat diare/muntah/demam'),
('MED006', 'PR002', 10000, 'Promag', 45, 12000, '2025-05-18', 'Tablet', '350 g', 'Menyembuhkan sakit maag'),
('MED007', 'PR003', 5000, 'Mylanta', 16, 7500, '2025-05-18', 'Tablet', '300 g', 'Menyembuhkan sakit maag'),
('MED008', 'PR004', 7000, 'Paracetamol', 30, 10000, '2026-03-06', 'Tablet', '200 g', 'Menyembuhkan sakit kepala dan nyeri'),
('MED009', 'PR005', 13000, 'Sangobion', 50, 15000, '2025-10-14', 'Kapsul', '320 g', 'Suplemen penambah darah'),
('MED010', 'PR006', 9000, 'Ester C', 60, 12000, '2027-01-11', 'Tablet', '250 g', 'Suplemen vitamin'),
('MED011', 'PR006', 6000, 'UC 1000', 30, 8500, '2025-05-18', 'Sirup', '30 ml', 'Suplemen vitamin'),
('MED012', 'PR007', 34000, 'Vitacimin', 40, 38000, '2025-05-18', 'Kapsul', '500 g', 'Suplemen vitamin'),
('MED013', 'PR007', 8500, 'Paratusin', 62, 11000, '2025-05-18', 'Tablet', '600 g', 'Menyembuhkan pilek'),
('MED014', 'PR008', 23000, 'Sakatonik ABC', 25, 27000, '2025-05-18', 'Tablet', '550 g', 'Suplemen vitamin'),
('MED015', 'PR009', 10000, 'Amoxilin', 45, 14000, '2025-05-18', 'Tablet', '300 g', 'Obat antibiotik'),
('MED016', 'PR009', 8000, 'Panadol', 30, 10000, '2025-05-18', 'Kapsul', '350 g', 'Menyembuhkan demam'),
('MED017', 'PR009', 17000, 'Ambeven', 20, 21000, '2025-05-18', 'Tablet', '370 g', 'Menyembuhkan wasir'),
('MED018', 'PR010', 13000, 'Caladine', 55, 15000, '2025-05-18', 'Salep', '200 g', 'Menyembuhkan gatal-gatal'),
('MED019', 'PR011', 16000, 'Hydrocortisone', 50, 19000, '2025-05-18', 'Salep', '250 g', 'Menyembuhkan alergi'),
('MED020', 'PR012', 21000, 'OB Herbal', 30, 23500, '2025-05-18', 'Sirup', '50 ml', 'Menyembuhkan sakit batuk'),
('MED021', 'PR004', 6500, 'Lapifed', 35, 9000, '2024-07-23', 'Sirup', '55 ml', 'Menyembuhkan pilek'),
('MED022', 'PR009', 8000, 'Cetirizine', 35, 10000, '2024-05-27', 'Tablet', '10 mg', 'Menyembuhkan gatal');

-- --------------------------------------------------------

--
-- Table structure for table `msprodusen`
--

CREATE TABLE `msprodusen` (
  `produsenID` char(5) NOT NULL,
  `produsenName` varchar(50) NOT NULL,
  `produsenPhone` varchar(14) NOT NULL,
  `produsenAddress` varchar(70) NOT NULL CHECK (octet_length(`produsenPhone`) between 12 and 14 and substr(`produsenPhone`,1,2) = '62' and `produsenPhone` regexp '^[0-9]+$' and `produsenID` regexp '^PR[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `msprodusen`
--

INSERT INTO `msprodusen` (`produsenID`, `produsenName`, `produsenPhone`, `produsenAddress`) VALUES
('PR001', 'PT. Jaya Makmur', '628111111111', 'Jl. Ikan Mas, Surabaya'),
('PR002', 'PT. Aman Sentosa', '628222222222', 'Jl. Ikan Patin, Surabaya'),
('PR003', 'PT. Maju Jaya', '6283333333333', 'Jl. Ikan Lele, Malang'),
('PR004', 'PT. Cahaya Nur', '6284444444444', 'Jl. Kemanggisan, Jakarta'),
('PR005', 'PT. Anak Agung', '6285555555555', 'Jl. Bulungcangkring, Jakarta'),
('PR006', 'PT. Bakti', '6286666666666', 'Jl. Tembalang, Jakarta'),
('PR007', 'PT. Subur Indah', '62877777777777', 'Jl. Pattimura, Jakarta'),
('PR008', 'PT. Kimia Farma', '62888888888888', 'Jl. Sayonara, Bandung'),
('PR009', 'PT. Kalbe Farma', '62899999999999', 'Jl. Cut Nyak Dien, Jakarta'),
('PR010', 'PT. Dexa Medica', '6281010101010', 'Jl. Kemenangan, Jakarta'),
('PR011', 'PT. Fahrenheit', '6281414141414', 'Jl. Blimbing, Surabaya'),
('PR012', 'PT. Hidup Sehat', '6281212121212', 'Jl. Lowokwaru, Bandung');

-- --------------------------------------------------------

--
-- Table structure for table `msstaff`
--

CREATE TABLE `msstaff` (
  `staffID` char(5) NOT NULL,
  `staffName` varchar(50) NOT NULL,
  `staffPhone` varchar(14) NOT NULL,
  `staffDOB` date NOT NULL,
  `staffAddress` varchar(70) DEFAULT NULL CHECK (octet_length(`staffPhone`) between 12 and 14 and substr(`staffPhone`,1,2) = '62' and `staffPhone` regexp '^[0-9]+$' and `staffID` regexp '^ST[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `msstaff`
--

INSERT INTO `msstaff` (`staffID`, `staffName`, `staffPhone`, `staffDOB`, `staffAddress`) VALUES
('ST001', 'Adi Nugroho', '6281234567890', '1990-05-15', 'Jl. Merdeka No. 10, Malang'),
('ST002', 'Putri Indah', '6282345678901', '1985-08-20', 'Jl. Sudirman No. 15, Batu'),
('ST003', 'Budi Santoso', '6283456789012', '1992-11-10', 'Jl. Pahlawan No. 5, Blitar'),
('ST004', 'Eka Surya', '6284567890123', '1987-04-25', 'Jl. Diponegoro No. 25, Probolinggo'),
('ST005', 'Lina Setiawati', '6285678901234', '1995-09-30', 'Jl. Gajah Mada No. 7, Kota Batu'),
('ST006', 'Putra Wirawan', '6286789012345', '1988-12-05', 'Jl. Mawar No. 12, Pasuruan'),
('ST007', 'Dewi Wulandari', '6287890123456', '1991-07-12', 'Jl. Surya Sumantri No. 17, Probolinggo'),
('ST008', 'Rudi Hidayat', '6288901234567', '1983-02-28', 'Jl. Ganesha No. 3, Blitar'),
('ST009', 'Ani Cahyani', '6289012345678', '1997-03-18', 'Jl. Panglima Sudirman No. 9, Kota Batu'),
('ST010', 'Sinta Riyanti', '6280123456789', '1986-06-22', 'Jl. Diponegoro No. 8, Pasuruan'),
('ST011', 'Bagus Kusuma', '6281234567890', '1994-01-09', 'Jl. Hayam Wuruk No. 16, Malang'),
('ST012', 'Sari Utami', '6282345678901', '1989-10-14', 'Jl. Pahlawan No. 20, Kota Batu'),
('ST013', 'Fajar Perdana', '6283456789012', '1993-12-01', 'Jl. Medan Merdeka No. 30, Blitar'),
('ST014', 'Rina Susanti', '6284567890123', '1984-07-27', 'Jl. Pemuda No. 50, Malang'),
('ST015', 'Doni Firmansyah', '6285678901234', '1998-08-03', 'Jl. Gajah Mada No. 40, Pasuruan'),
('ST016', 'Larasati Widya', '6286789012345', '1982-11-19', 'Jl. Thamrin No. 23, Probolinggo'),
('ST017', 'Reza Aditya', '6287890123456', '1996-04-17', 'Jl. Sudirman No. 35, Malang'),
('ST018', 'Nina Permata', '6288901234567', '1981-05-08', 'Jl. Pahlawan No. 10, Kota Batu'),
('ST019', 'Andi Kurniawan', '6289012345678', '1990-02-25', 'Jl. Diponegoro No. 5, Blitar'),
('ST020', 'Dini Ariska', '6280123456789', '1987-06-11', 'Jl. Ganesha No. 9, Probolinggo');

-- --------------------------------------------------------

--
-- Stand-in structure for view `nota_pembelian`
-- (See below for the actual view)
--
CREATE TABLE `nota_pembelian` (
`transactionDate` date
,`customerName` varchar(50)
,`staffName` varchar(50)
,`obatName` varchar(50)
,`jumlahBeli` int(11)
,`hargaJual` int(11)
,`Total` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `total_transaksi_pembelian`
-- (See below for the actual view)
--
CREATE TABLE `total_transaksi_pembelian` (
`transactionDate` date
,`customerName` varchar(50)
,`TotalPembelian` decimal(42,0)
);

-- --------------------------------------------------------

--
-- Table structure for table `transactiondetail`
--

CREATE TABLE `transactiondetail` (
  `transDetailID` char(5) NOT NULL,
  `transactionID` char(5) NOT NULL,
  `obatID` char(6) NOT NULL,
  `jumlahBeli` int(11) NOT NULL CHECK (`transDetailID` regexp '^TD[0-9]{3}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactiondetail`
--

INSERT INTO `transactiondetail` (`transDetailID`, `transactionID`, `obatID`, `jumlahBeli`) VALUES
('TD001', 'TR001', 'MED006', 2),
('TD002', 'TR001', 'MED002', 1),
('TD003', 'TR002', 'MED011', 3),
('TD004', 'TR003', 'MED001', 1),
('TD005', 'TR004', 'MED009', 5),
('TD006', 'TR005', 'MED003', 2),
('TD007', 'TR006', 'MED008', 1),
('TD008', 'TR007', 'MED016', 4),
('TD009', 'TR007', 'MED020', 2),
('TD010', 'TR008', 'MED004', 6),
('TD011', 'TR009', 'MED007', 1),
('TD012', 'TR009', 'MED001', 2),
('TD013', 'TR010', 'MED013', 3),
('TD014', 'TR011', 'MED007', 4);

-- --------------------------------------------------------

--
-- Table structure for table `transactionheader`
--

CREATE TABLE `transactionheader` (
  `transactionID` char(5) NOT NULL,
  `staffID` char(5) NOT NULL,
  `customerID` char(5) NOT NULL,
  `transactionDate` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactionheader`
--

INSERT INTO `transactionheader` (`transactionID`, `staffID`, `customerID`, `transactionDate`) VALUES
('TR001', 'ST001', 'CU001', '2023-01-15'),
('TR002', 'ST002', 'CU002', '2023-02-20'),
('TR003', 'ST003', 'CU001', '2023-03-10'),
('TR004', 'ST002', 'CU004', '2023-05-25'),
('TR005', 'ST005', 'CU005', '2023-05-30'),
('TR006', 'ST003', 'CU006', '2023-06-12'),
('TR007', 'ST007', 'CU007', '2023-07-12'),
('TR008', 'ST008', 'CU008', '2023-08-28'),
('TR009', 'ST007', 'CU006', '2023-09-18'),
('TR010', 'ST010', 'CU010', '2023-12-05'),
('TR011', 'ST003', 'CU011', '2023-12-04');

-- --------------------------------------------------------

--
-- Structure for view `informasi_produsen`
--
DROP TABLE IF EXISTS `informasi_produsen`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `informasi_produsen`  AS SELECT `p`.`produsenName` AS `produsenName`, `p`.`produsenPhone` AS `produsenPhone`, `p`.`produsenAddress` AS `produsenAddress`, group_concat(`o`.`obatName` separator ',') AS `Nama Obat` FROM (`msobat` `o` join `msprodusen` `p` on(`p`.`produsenID` = `o`.`produsenID`)) GROUP BY `p`.`produsenName` ;

-- --------------------------------------------------------

--
-- Structure for view `nota_pembelian`
--
DROP TABLE IF EXISTS `nota_pembelian`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `nota_pembelian`  AS SELECT `th`.`transactionDate` AS `transactionDate`, `c`.`customerName` AS `customerName`, `s`.`staffName` AS `staffName`, `o`.`obatName` AS `obatName`, `td`.`jumlahBeli` AS `jumlahBeli`, `o`.`hargaJual` AS `hargaJual`, `o`.`hargaJual`* `td`.`jumlahBeli` AS `Total` FROM ((((`transactionheader` `th` join `mscustomer` `c` on(`c`.`customerID` = `th`.`customerID`)) join `msstaff` `s` on(`s`.`staffID` = `th`.`staffID`)) join `transactiondetail` `td` on(`td`.`transactionID` = `th`.`transactionID`)) join `msobat` `o` on(`o`.`obatID` = `td`.`obatID`)) ;

-- --------------------------------------------------------

--
-- Structure for view `total_transaksi_pembelian`
--
DROP TABLE IF EXISTS `total_transaksi_pembelian`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `total_transaksi_pembelian`  AS SELECT `th`.`transactionDate` AS `transactionDate`, `c`.`customerName` AS `customerName`, sum(`o`.`hargaJual` * `td`.`jumlahBeli`) AS `TotalPembelian` FROM (((`transactionheader` `th` join `mscustomer` `c` on(`c`.`customerID` = `th`.`customerID`)) join `transactiondetail` `td` on(`td`.`transactionID` = `th`.`transactionID`)) join `msobat` `o` on(`o`.`obatID` = `td`.`obatID`)) GROUP BY `th`.`transactionID` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `mscustomer`
--
ALTER TABLE `mscustomer`
  ADD PRIMARY KEY (`customerID`);

--
-- Indexes for table `msobat`
--
ALTER TABLE `msobat`
  ADD PRIMARY KEY (`obatID`),
  ADD KEY `produsenID` (`produsenID`);

--
-- Indexes for table `msprodusen`
--
ALTER TABLE `msprodusen`
  ADD PRIMARY KEY (`produsenID`);

--
-- Indexes for table `msstaff`
--
ALTER TABLE `msstaff`
  ADD PRIMARY KEY (`staffID`);

--
-- Indexes for table `transactiondetail`
--
ALTER TABLE `transactiondetail`
  ADD PRIMARY KEY (`transDetailID`),
  ADD KEY `transactionID` (`transactionID`),
  ADD KEY `obatID` (`obatID`);

--
-- Indexes for table `transactionheader`
--
ALTER TABLE `transactionheader`
  ADD PRIMARY KEY (`transactionID`),
  ADD KEY `staffID` (`staffID`),
  ADD KEY `customerID` (`customerID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `msobat`
--
ALTER TABLE `msobat`
  ADD CONSTRAINT `msobat_ibfk_1` FOREIGN KEY (`produsenID`) REFERENCES `msprodusen` (`produsenID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transactiondetail`
--
ALTER TABLE `transactiondetail`
  ADD CONSTRAINT `transactiondetail_ibfk_1` FOREIGN KEY (`transactionID`) REFERENCES `transactionheader` (`transactionID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `transactiondetail_ibfk_2` FOREIGN KEY (`obatID`) REFERENCES `msobat` (`obatID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `transactionheader`
--
ALTER TABLE `transactionheader`
  ADD CONSTRAINT `transactionheader_ibfk_1` FOREIGN KEY (`staffID`) REFERENCES `msstaff` (`staffID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `transactionheader_ibfk_2` FOREIGN KEY (`customerID`) REFERENCES `mscustomer` (`customerID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
