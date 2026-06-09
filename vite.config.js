import { mkdirSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

function buildVersionPlugin() {
  return {
    name: 'mast-build-version',
    buildStart() {
      const version = `${process.env.COMMIT_REF || 'local'}-${Date.now()}`
      const filePath = resolve(__dirname, 'public', 'deploy-version.json')
      mkdirSync(resolve(__dirname, 'public'), { recursive: true })
      writeFileSync(
        filePath,
        JSON.stringify({ version, builtAt: new Date().toISOString() }, null, 2)
      )
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), buildVersionPlugin()],
})
