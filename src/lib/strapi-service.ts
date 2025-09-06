import qs from 'qs';

const STRAPI_URL =
  process.env.NEXT_PUBLIC_STRAPI_API_URL || 'http://localhost:1337';
const STRAPI_API_TOKEN = process.env.STRAPI_API_TOKEN;

interface FetchOptions extends RequestInit {
  // You can add any custom options here if needed
}

/**
 * Fetches data from the Strapi API.
 * @param path The API path to fetch (e.g., '/api/pages').
 * @param params Query parameters for the request.
 * @param options Additional fetch options.
 * @returns The fetched data as a JSON object.
 * @throws An error if the fetch request fails.
 */
export async function fetchFromStrapi<T>(
  path: string,
  params: Record<string, any> = {},
  options: FetchOptions = {}
): Promise<T> {
  const defaultOptions: FetchOptions = {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `bearer ${STRAPI_API_TOKEN}`,
    },
    next: {
      // Revalidate every 60 seconds. Adjust as needed.
      revalidate: 60,
    },
    ...options,
  };

  const queryString = qs.stringify(params, { encodeValuesOnly: true });
  const requestUrl = `${STRAPI_URL}${path}${queryString ? `?${queryString}` : ''}`;

  try {
    const response = await fetch(requestUrl, defaultOptions);

    if (!response.ok) {
      console.error(
        `Strapi fetch error: ${response.status} ${response.statusText} for URL: ${requestUrl}`
      );
      const errorBody = await response.json();
      console.error('Error body:', JSON.stringify(errorBody, null, 2));
      throw new Error(`Failed to fetch from Strapi: ${response.statusText}`);
    }

    const data = await response.json();
    return data as T;
  } catch (error) {
    console.error('An error occurred while fetching from Strapi:', error);
    throw new Error('Could not fetch data from Strapi.');
  }
}
