Smart Inventory System (AI-Powered)

An AI-powered, enterprise-grade Java web application designed to automate stock management, streamline supply chains, and optimize warehouse operations. Built natively using Apache NetBeans, this system provides real-time tracking, automated reorder triggers, and smart insights to eliminate stockouts and overstocking.

🚀 Key Features
* **Real-Time Stock Tracking**: Seamless monitoring of inventory levels across multiple categories.
* **Automated Low-Stock Alerts**: Proactive system notifications when items fall below a predefined buffer threshold.
* **Database Driven**: Fully structured SQL backend storing historic sales, item logs, and vendor information.
* **Responsive Control Panel**: Clean dashboard interface styled with CSS and enhanced with interactive JavaScript workflows.

🛠️ Tech Stack
* **Backend**: Java (Servlets, JSP)
* **Frontend**: HTML5, CSS3, JavaScript
* **Database**: MySQL / PostgreSQL (Configured via `database.sql`)
* **Project Management & Build**: Maven (`pom.xml`)
* **IDE Support**: Apache NetBeans (`nb-configuration.xml`)

⚙️ Prerequisites
Before running the project, ensure you have the following installed:
* Java Development Kit (JDK) 8 or higher
* Apache Tomcat Server (v9.0 or later recommended)
* Apache NetBeans IDE
* MySQL Server

🔧 Installation & Setup

1. **Clone the Repository**
   ```bash
   git clone https://github.com/faizerumar/Smart-Inventory-System-AI-Powered.git
   cd Smart-Inventory-System-AI-Powered
   ```

2. **Database Setup**
   * Open your SQL Database client (e.g., MySQL Workbench).
   * Create a new database schema: `CREATE DATABASE smart_inventory;`.
   * Import and execute the `database.sql` script located in the project root directory to construct the required tables and sample data.

3. **IDE Import & Configuration**
   * Open **Apache NetBeans**.
   * Go to `File` -> `Open Project` and select the cloned project folder (NetBeans will recognize it instantly via the Maven `pom.xml`).
   * Clean and Build the project to automatically download all required dependencies.

4. **Deployment**
   * Right-click the project name in NetBeans and select **Run**.
   * Select your target **Apache Tomcat Server** instance.
   * Access the local deployment via your browser at: `http://localhost:8080/SmartInventorySystem/`
