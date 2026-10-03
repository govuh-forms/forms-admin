/// <reference types="vitest" />

import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import * as path from 'node:path'
import { NodePackageImporter } from 'sass'
import { copyFileSync, mkdirSync } from 'node:fs'

// Publish approved UH Site Identity files after Vite clears and rebuilds the
// genuine Forms Admin asset output. Artwork is maintained in app/frontend/identity.
function approvedUhIdentityAssets () {
  return {
    name: 'govuh-forms-admin-approved-identity-assets',
    apply: 'build',
    closeBundle () {
      const output = path.resolve(__dirname, 'public/assets/forms-admin')
      const source = path.resolve(__dirname, 'app/frontend/identity')
      mkdirSync(output, { recursive: true })
      const files = [
        'uh-approved-crown.png',
        'uh-approved-icon-48.png',
        'uh-approved-icon-180.png',
        'uh-approved-icon-192.png',
        'uh-approved-icon-512.png'
      ]
      for (const filename of files) {
        copyFileSync(path.join(source, filename), path.join(output, filename))
      }
      copyFileSync(
        path.resolve(__dirname, 'public/manifest.json'),
        path.join(output, 'manifest.json')
      )
    }
  }
}

export default defineConfig({
  plugins: [RubyPlugin(), approvedUhIdentityAssets()],
  build: {
    emptyOutDir: true,
    cssMinify: 'esbuild'
  },
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern',
        importers: [new NodePackageImporter()],
        quietDeps: true
      },
      devSourcemaps: true
    },
    transformer: 'postcss'
  },
  resolve: {
    alias: {
      '@govuk': path.resolve(
        __dirname,
        'node_modules/govuk-frontend/dist/govuk'
      ),
      '@images': path.resolve(__dirname, 'app/frontend/images')
    }
  },
  test: {
    globals: true,
    setupFiles: ['test/setup.js']
  },
  cacheDir: '../../node_modules/.vite'
})
