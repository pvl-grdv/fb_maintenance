# Firebird Database Maintenance Toolkit

A comprehensive batch script for automated maintenance of Firebird databases in EcoDB format. This toolkit provides a complete solution for database administrators and users of UPRZA Ecolog systems to perform routine maintenance tasks.

## Features

- Automated backup and restoration of Firebird databases
- Database validation and repair
- Transaction management and garbage collection
- Detailed logging of all operations
- Support for both single and batch database processing
- Customizable paths for databases, backups, and logs

## Usage

The script accepts various command-line parameters to customize operation:
```
ecodb_maintenance.cmd [PARAMETERS]
```

Key parameters include:
- `-u USERNAME`: Firebird username (default: SYSDBA)
- `-p PASSWORD`: Firebird password (default: masterkey)
- `-d PATH`: Directory containing databases (default: current directory)
- `-f PATTERN`: File pattern for processing (default: *.ecodb)
- `-b PATH`: Backup directory (default: .\backup)
- `-l PATH`: Log directory (default: .\log)

Use `-h` or `--help` to display full usage information.

## Requirements

- Firebird SQL Database installed (default path: C:\Program Files (x86)\Integral\FireBird\bin)
- Administrator privileges to modify database files

This toolkit is specifically designed for maintaining databases used with the UPRZA Ecolog system.