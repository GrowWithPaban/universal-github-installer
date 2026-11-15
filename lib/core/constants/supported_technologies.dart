enum ProgrammingLanguage {
  php,
  nodeJs,
  python,
  java,
  go,
  rust,
  dotnet,
  ruby,
  staticWeb,
  dockerCompose,
  unknown;

  String get displayName {
    switch (this) {
      case ProgrammingLanguage.php:
        return 'PHP';
      case ProgrammingLanguage.nodeJs:
        return 'Node.js / JavaScript / TypeScript';
      case ProgrammingLanguage.python:
        return 'Python';
      case ProgrammingLanguage.java:
        return 'Java';
      case ProgrammingLanguage.go:
        return 'Go';
      case ProgrammingLanguage.rust:
        return 'Rust';
      case ProgrammingLanguage.dotnet:
        return '.NET / C#';
      case ProgrammingLanguage.ruby:
        return 'Ruby';
      case ProgrammingLanguage.staticWeb:
        return 'Static Website / HTML';
      case ProgrammingLanguage.dockerCompose:
        return 'Docker Compose';
      case ProgrammingLanguage.unknown:
        return 'Unknown / Custom';
    }
  }
}

enum FrameworkType {
  // PHP
  laravel,
  codeIgniter3,
  codeIgniter4,
  wordPress,
  symfony,
  corePhp,
  composerPackage,

  // Node.js
  express,
  nextJs,
  react,
  vue,
  angular,
  nuxt,
  nestJs,
  vite,
  vanillaNode,

  // Python
  django,
  flask,
  fastApi,
  streamlit,
  generalPython,

  // General
  dockerized,
  staticHtml,
  custom;

  String get displayName {
    switch (this) {
      case FrameworkType.laravel:
        return 'Laravel';
      case FrameworkType.codeIgniter3:
        return 'CodeIgniter 3';
      case FrameworkType.codeIgniter4:
        return 'CodeIgniter 4';
      case FrameworkType.wordPress:
        return 'WordPress';
      case FrameworkType.symfony:
        return 'Symfony';
      case FrameworkType.corePhp:
        return 'Core PHP';
      case FrameworkType.composerPackage:
        return 'Composer Package';
      case FrameworkType.express:
        return 'Express.js';
      case FrameworkType.nextJs:
        return 'Next.js';
      case FrameworkType.react:
        return 'React (SPA)';
      case FrameworkType.vue:
        return 'Vue.js';
      case FrameworkType.angular:
        return 'Angular';
      case FrameworkType.nuxt:
        return 'Nuxt.js';
      case FrameworkType.nestJs:
        return 'NestJS';
      case FrameworkType.vite:
        return 'Vite';
      case FrameworkType.vanillaNode:
        return 'Node.js Server';
      case FrameworkType.django:
        return 'Django';
      case FrameworkType.flask:
        return 'Flask';
      case FrameworkType.fastApi:
        return 'FastAPI';
      case FrameworkType.streamlit:
        return 'Streamlit';
      case FrameworkType.generalPython:
        return 'Python Application';
      case FrameworkType.dockerized:
        return 'Docker Compose Stack';
      case FrameworkType.staticHtml:
        return 'Static Web Site';
      case FrameworkType.custom:
        return 'Custom Application';
    }
  }
}

enum DatabaseType {
  none,
  sqlite,
  mysql,
  mariadb,
  postgresql,
  mongodb;

  String get displayName {
    switch (this) {
      case DatabaseType.none:
        return 'None / Not Required';
      case DatabaseType.sqlite:
        return 'SQLite';
      case DatabaseType.mysql:
        return 'MySQL';
      case DatabaseType.mariadb:
        return 'MariaDB';
      case DatabaseType.postgresql:
        return 'PostgreSQL';
      case DatabaseType.mongodb:
        return 'MongoDB';
    }
  }
}

enum ProjectState {
  notInstalled,
  cloning,
  analyzing,
  installing,
  ready,
  running,
  starting,
  stopping,
  error,
}
