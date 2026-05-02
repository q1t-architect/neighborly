"use client";

import { useEffect } from "react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center">
      <div className="text-center">
        <h2 className="text-2xl font-semibold text-gray-900 dark:text-white">
          Something went wrong
        </h2>
        <p className="mt-2 text-gray-500">
          {error.message ?? "An unexpected error occurred."}
        </p>
        <button
          onClick={reset}
          className="mt-6 rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white hover:bg-green-700"
        >
          Try again
        </button>
      </div>
    </main>
  );
}
