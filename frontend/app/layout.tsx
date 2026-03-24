import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import Link from "next/link";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Phishing Detection System",
  description: "ML-powered phishing URL detection and analysis",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <div className="min-h-screen flex flex-col">
          <header className="border-b border-neutral-200">
            <nav className="max-w-7xl mx-auto px-6 py-4">
              <div className="flex items-center justify-between">
                <Link href="/" className="text-xl font-semibold tracking-tight hover:opacity-60 transition-opacity">
                  Phishing Detection
                </Link>
                <div className="hidden md:flex items-center gap-8">
                  <Link href="/" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    Home
                  </Link>
                  <Link href="/playground" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    Playground
                  </Link>
                  <Link href="/datasets" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    Datasets
                  </Link>
                  <Link href="/pipeline" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    Pipeline
                  </Link>
                  <Link href="/model" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    Model
                  </Link>
                  <Link href="/api-docs" className="text-sm text-neutral-600 hover:text-black transition-colors">
                    API
                  </Link>
                </div>
              </div>
            </nav>
          </header>
          <main className="flex-1">
            {children}
          </main>
          <footer className="border-t border-neutral-200 mt-auto pb-16 md:pb-0">
            <div className="max-w-7xl mx-auto px-6 py-8">
              <p className="text-sm text-neutral-500 text-center md:text-left">
                Network Security ML Pipeline · Built with R + Next.js
              </p>
            </div>
          </footer>

          {/* Mobile Bottom Navigation */}
          <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-neutral-200 z-50 pb-safe">
            <div className="flex items-center justify-around px-2 py-3 w-full">
              <Link href="/" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">Home</span>
              </Link>
              <Link href="/playground" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">Playground</span>
              </Link>
              <Link href="/datasets" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">Data</span>
              </Link>
              <Link href="/pipeline" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">Pipeline</span>
              </Link>
              <Link href="/model" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">Model</span>
              </Link>
              <Link href="/api-docs" className="flex flex-col items-center text-neutral-600 hover:text-black">
                <span className="text-xs font-medium mt-1">API</span>
              </Link>
            </div>
          </nav>
        </div>
      </body>
    </html>
  );
}
