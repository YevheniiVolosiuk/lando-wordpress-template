# Lando WordPress Template 🛠️🎉

## Introduction 🚀

This repository provides a **Lando-based environment** for WordPress development. It's designed for **WordPress developers** who want a clean, flexible, and efficient local development setup. It comes with pre-configured services like **Redis**, **Mailhog**, and **PhpMyAdmin** to make development easier and faster.

## Quick Start 🏁

### Prerequisites ✅
- [Lando](https://lando.dev) must be installed. Follow the [Lando Docs](https://docs.lando.dev) for installation instructions.

### Getting Started

1. **Clone the repository:**

    ```bash
    git clone https://github.com/YevheniiVolosiuk/lando-wordpress-template.git
    cd lando-wordpress-template
    ```

2. **Start the Lando environment:**

    ```bash
    lando start
    ```

3. **Install WordPress:**

    ```bash
    lando install:wp
    ```

   This command will install a fresh copy of WordPress with basic configuration.

4. **Set up WordPress (clean default content):**

    ```bash
    lando setup:wp
    ```

   This will clean up the default posts, pages, comments, and apply some initial site settings.

## Included Services 🧰

- **Redis:** Object caching is enabled by default for improved performance. 🔥
- **Mailhog:** Catch and view outgoing emails in a dev environment. 📧
- **PhpMyAdmin:** Easily manage your database via PhpMyAdmin (access at `http://pma.wordpress-app.lndo.site`). 🗄️

### Available Commands ⚙️

Here are some useful commands you can run via Lando:

- **`lando install:wp`** - Install a fresh WordPress setup with basic configuration. 💻
- **`lando setup:wp`** - Clean up default content (posts, pages, comments) and apply initial settings. 🧹
- **`lando install:redis`** - Install and enable Redis object caching. 🚀

For any other WordPress-related operations, use **WP-CLI** with the command:

- **`lando wp [command]`** - Run any WP-CLI command (e.g., `lando wp plugin install acf`). ⚡

## Directory Structure 📂

This project follows a specific directory structure:

- `.lando.yml`: Lando configuration file for the project. ⚙️
- `.lando/bin/`: Contains custom scripts for various tasks (like setting up WordPress or Redis). 📝
- `.lando/utils/`: Contains utility scripts for your Lando environment. 🛠️
- `public/`: The WordPress root directory where your WordPress installation lives. 🏠

## Extending the Environment 🌱

This template is designed to be easily extendable. You can:

- Add custom services (e.g., Xdebug for PHP debugging). 🐞
- Add additional WordPress plugins or themes. 🎨
- Customize the environment to fit your specific development needs. 🔧

For example, you can add Xdebug for local PHP debugging by editing the `.lando.yml` file and adding the Xdebug service.

## Contributing 💡

We welcome contributions! If you'd like to improve this template, please fork the repo and create a pull request.

### To extend:
- **Fork the repository** 🍴
- **Create a new branch** (`git checkout -b my-feature`) 🌳
- **Commit your changes** (`git commit -am 'Add new feature'`) 📝
- **Push to your fork** (`git push origin my-feature`) 🚀
- **Create a pull request** against the `main` branch 🎯

## License 📜

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. ⚖️
