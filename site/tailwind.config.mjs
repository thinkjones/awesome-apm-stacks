/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Brand triad (Four Signals 2.1 "The Light Architect")
        'brand-orange': 'var(--brand-orange)',
        'brand-orange-light': 'var(--brand-orange-light)',
        'brand-orange-soft': 'var(--brand-orange-soft)',
        'brand-cyan': 'var(--brand-cyan)',
        'brand-rose': 'var(--brand-rose)',

        // Surfaces (theme-aware via CSS vars)
        'bg-primary': 'var(--bg-primary)',
        'bg-secondary': 'var(--bg-secondary)',
        'bg-card': 'var(--bg-card)',
        'bg-card-hover': 'var(--bg-card-hover)',

        // Text
        'text-primary': 'var(--text-primary)',
        'text-secondary': 'var(--text-secondary)',
        'text-muted': 'var(--text-muted)',

        // CTA
        'cta-primary': 'var(--cta-primary)',

        // Border
        border: 'var(--border)',

        // Signal accents (vibrant)
        'accent-cyan': '#00f5ff',
        'accent-purple': '#d000ff',
        'accent-amber': '#ffb800',
        'accent-green': '#00ff88',
        'accent-rose': '#EB5570',
      },
      fontFamily: {
        headline: ['Source Serif 4', 'Georgia', 'serif'],
        body: ['Inter', 'system-ui', 'sans-serif'],
        serif: ['Source Serif 4', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'SF Mono', 'Fira Code', 'monospace'],
      },
      fontSize: {
        'display-xl': ['4.5rem', { lineHeight: '1.08', letterSpacing: '-0.075em', fontWeight: '700' }],
        'display-lg': ['3.75rem', { lineHeight: '1.1', letterSpacing: '-0.05em', fontWeight: '700' }],
        'display-md': ['3rem', { lineHeight: '1.15', letterSpacing: '-0.05em', fontWeight: '600' }],
        'headline-lg': ['2.25rem', { lineHeight: '1.2', letterSpacing: '-0.05em', fontWeight: '600' }],
        'headline-md': ['1.875rem', { lineHeight: '1.25', letterSpacing: '-0.03em', fontWeight: '600' }],
        'headline-sm': ['1.5rem', { lineHeight: '1.3', letterSpacing: '-0.02em', fontWeight: '600' }],
        'body-lg': ['1.125rem', { lineHeight: '1.625', fontWeight: '400' }],
        'body-md': ['1rem', { lineHeight: '1.625', fontWeight: '400' }],
        'body-sm': ['0.875rem', { lineHeight: '1.6', fontWeight: '400' }],
        'label-lg': ['0.875rem', { lineHeight: '1.4', letterSpacing: '0.02em', fontWeight: '500' }],
        'label-md': ['0.75rem', { lineHeight: '1.4', letterSpacing: '0.04em', fontWeight: '400' }],
        'label-sm': ['0.6875rem', { lineHeight: '1.4', letterSpacing: '0.2em', fontWeight: '400' }],
        'stat-number': ['3rem', { lineHeight: '1.1', letterSpacing: '-0.05em', fontWeight: '700' }],
      },
      letterSpacing: {
        tighter: '-0.05em',
        tightest: '-0.075em',
        widest: '0.2em',
      },
      borderRadius: {
        none: '0px',
        sm: '2px',
        DEFAULT: '4px',
        md: '4px',
        lg: '4px',
        full: '9999px',
      },
      boxShadow: {
        'sculptural': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
        'none': 'none',
      },
      transitionDuration: {
        '500': '500ms',
        '700': '700ms',
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};
