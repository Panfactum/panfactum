import Link from 'next/link'

export default function Page () {
  return (
    <div className="max-w-7xl m-auto bg-base-100 h-screen flex flex-col justify-center items-center p-4">
      <div className="bg-neutral p-12 rounded-lg drop-shadow-md">
        <h1 className="text-primary text-2xl md:text-4xl font-semibold max-w-4xl">
          This page is like a fine wine; it gets better with time. Check back later!
        </h1>
        <p className="text-lg md:text-xl my-8">
          Coming soon...
        </p>
        <Link
          className="btn"
          href="/"
        >
          {' '}
          Back to main site
        </Link>
      </div>
    </div>
  )
}
