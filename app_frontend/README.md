# Expense Manager - Frontend

Frontend de la aplicación Expense Manager desarrollado con Next.js 16, React 19 y TypeScript.

## 📋 Descripción

Interfaz de usuario moderna y responsive para la gestión de gastos personales. Permite a los usuarios registrar gastos, crear categorías personalizadas y visualizar estadísticas de sus gastos.

## 🚀 Tecnologías

- **Next.js 16** - Framework React con App Router
- **React 19** - Biblioteca de interfaces de usuario
- **TypeScript** - Tipado estático
- **Tailwind CSS** - Framework de estilos
- **Context API** - Gestión de estado para autenticación

## 🛠️ Instalación y Desarrollo

### Desarrollo Local (sin Docker)

```bash
# Instalar dependencias
npm install

# Ejecutar servidor de desarrollo
npm run dev
```

Abre [http://localhost:3000](http://localhost:3000) en tu navegador.

### Desarrollo con Docker

El frontend está configurado para ejecutarse en Docker. Consulta el README principal del proyecto para más detalles sobre cómo levantar todos los servicios.

## 📁 Estructura del Proyecto

```
app_frontend/
├── app/                    # App Router de Next.js
│   ├── dashboard/          # Página del dashboard
│   ├── expenses/           # Página de gastos
│   ├── categories/         # Página de categorías
│   ├── login/              # Página de inicio de sesión
│   ├── register/           # Página de registro
│   └── layout.tsx          # Layout principal
├── components/             # Componentes reutilizables
│   ├── Navbar.tsx          # Barra de navegación
│   ├── LoginForm.tsx       # Formulario de login
│   └── RegisterForm.tsx  # Formulario de registro
├── contexts/               # Contextos de React
│   └── AuthContext.tsx    # Contexto de autenticación
└── lib/                    # Utilidades
    └── api.ts              # Cliente API para comunicación con backend
```

## 🔧 Configuración

### Variables de Entorno

El frontend requiere la siguiente variable de entorno:

```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
```

Esta variable se configura en `docker-compose.yml` o en un archivo `.env.local` para desarrollo local.

## 🎨 Características

- ✅ Interfaz de usuario moderna y responsive
- ✅ Autenticación persistente con tokens
- ✅ Navegación con App Router de Next.js
- ✅ Gestión de estado con Context API
- ✅ Formularios interactivos con validación
- ✅ Visualización de datos con Tailwind CSS
- ✅ Selectores visuales de iconos y colores
- ✅ Formato de fechas y monedas

## 📱 Páginas Disponibles

- **Dashboard** (`/dashboard`): Resumen de gastos y estadísticas
- **Gastos** (`/expenses`): Lista y gestión de gastos
- **Categorías** (`/categories`): Creación y gestión de categorías
- **Login** (`/login`): Inicio de sesión
- **Registro** (`/register`): Registro de nuevos usuarios

## 🔗 Integración con Backend

El frontend se comunica con el backend Laravel a través de la API REST:

- **URL Base**: Configurada en `NEXT_PUBLIC_API_URL`
- **Autenticación**: Tokens Bearer usando Laravel Sanctum
- **Cliente API**: Implementado en `lib/api.ts`

## 🚀 Build de Producción

```bash
# Construir para producción
npm run build

# Iniciar servidor de producción
npm start
```

## 📚 Recursos

- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs)

## 📝 Notas

Este proyecto es parte de un sistema completo de Integración Continua que incluye:
- Backend Laravel (API REST)
- Frontend Next.js (esta aplicación)
- Jenkins (CI/CD)
- Gitea (Control de versiones)
- MailHog (Notificaciones)

Para más información sobre el proyecto completo, consulta el [README principal](../README.md).
