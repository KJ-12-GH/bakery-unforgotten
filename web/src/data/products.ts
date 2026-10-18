import type { Product } from '../types'

/** Bakery catalogue used across the prototype. */
export const PRODUCTS: Product[] = [
  { id: 'croissant', name: 'ครัวซองต์', nameEn: 'Croissant', emoji: '🥐' },
  { id: 'milk-bread', name: 'ขนมปังนมสด', nameEn: 'Fresh Milk Bread', emoji: '🍞' },
  { id: 'choc-bread', name: 'ขนมปังช็อกโกแลต', nameEn: 'Chocolate Bread', emoji: '🍫' },
  { id: 'donut', name: 'โดนัท', nameEn: 'Donut', emoji: '🍩' },
  { id: 'almond-croissant', name: 'ครัวซองต์อัลมอนด์', nameEn: 'Almond Croissant', emoji: '🥐' },
  { id: 'walnut-bread', name: 'ขนมปังวอลนัท', nameEn: 'Walnut Bread', emoji: '🌰' },
  { id: 'butter-cake', name: 'เค้กเนยสด', nameEn: 'Butter Cake', emoji: '🍰' },
  { id: 'mochi-bread', name: 'ขนมปังโมจิ', nameEn: 'Mochi Bread', emoji: '🍡' },
]

const PRODUCT_MAP: Record<string, Product> = Object.fromEntries(
  PRODUCTS.map((product) => [product.id, product]),
)

export function getProduct(id: string): Product {
  return PRODUCT_MAP[id] ?? { id, name: id, nameEn: id, emoji: '🍞' }
}
