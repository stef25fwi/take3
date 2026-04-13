const API_URL = 'http://localhost:4000';

export async function fetchJson(path) {
  const response = await fetch(`${API_URL}${path}`);

  if (!response.ok) {
    throw new Error('Request failed');
  }

  return response.json();
}
