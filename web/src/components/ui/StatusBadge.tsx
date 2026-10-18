import type { Order } from '../../types'
import { orderStatusLabel, orderStatusTone } from '../../utils/labels'
import { Badge } from './Badge'

interface StatusBadgeProps {
  order: Order
  dot?: boolean
}

export function StatusBadge({ order, dot = true }: StatusBadgeProps) {
  return (
    <Badge tone={orderStatusTone(order)} dot={dot}>
      {orderStatusLabel(order)}
    </Badge>
  )
}
