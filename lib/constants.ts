// Non-mock constants — safe to import from both Server and Client Components

export const CATEGORIES = [
  "Tools",
  "Electronics",
  "Sports",
  "Books",
  "Clothes",
  "Kitchen",
  "Garden",
  "Kids",
  "Music",
  "Other",
] as const;

export type Category = (typeof CATEGORIES)[number];

export const MADRID_NEIGHBORHOODS = [
  "Malasaña",
  "Chueca",
  "Lavapiés",
  "La Latina",
  "Moncloa",
  "Chamberí",
  "Salamanca",
  "Retiro",
  "Arganzuela",
  "Carabanchel",
  "Vallecas",
  "Hortaleza",
  "Móstoles",
  "Alcalá de Henares",
] as const;

export type Neighborhood = (typeof MADRID_NEIGHBORHOODS)[number];

export const PRICE_TYPES = ["free", "symbolic"] as const;
export type PriceType = (typeof PRICE_TYPES)[number];

export const LISTING_STATUSES = ["available", "reserved", "given"] as const;
export type ListingStatus = (typeof LISTING_STATUSES)[number];

export const DEFAULT_CENTER = {
  lat: 40.4168,
  lng: -3.7038,
} as const;

export const DEFAULT_RADIUS_KM = 25;
export const DEFAULT_LIMIT = 50;
