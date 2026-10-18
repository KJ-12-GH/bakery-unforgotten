//
//  ComparisonList.swift
//  BakeCheck
//
//  Per-product expected vs detected comparison, with an optional correction
//  affordance for staff.
//

import SwiftUI

struct ComparisonList: View {
    var rows: [ComparisonRow]
    var onEdit: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            header
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    BakeSeparator()
                }
                ComparisonRowView(row: row, onEdit: onEdit)
            }
        }
        .background(BakeColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BakeRadius.md, style: .continuous)
                .stroke(BakeColor.border, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: BakeSpace.s2) {
            Text("สินค้า")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("สั่ง")
                .frame(width: 34)
            Text("ตรวจพบ")
                .frame(width: 56)
            Text("ต่าง")
                .frame(width: 44)
        }
        .font(BakeFont.tiny.weight(.semibold))
        .foregroundStyle(BakeColor.muted)
        .padding(.horizontal, BakeSpace.s3)
        .padding(.vertical, BakeSpace.s2)
        .background(BakeColor.surfaceSunken)
    }
}

struct ComparisonRowView: View {
    var row: ComparisonRow
    var onEdit: ((String) -> Void)? = nil

    private var product: Product { SeedData.product(row.productId) }
    private var corrected: Bool { row.manualQty != nil && row.manualQty != row.detectedQty }

    var body: some View {
        VStack(alignment: .leading, spacing: BakeSpace.s2) {
            HStack(alignment: .top, spacing: BakeSpace.s2) {
                Text(product.emoji)
                    .font(.system(size: 20))
                    .frame(width: 34, height: 34)
                    .background(BakeColor.surfaceSunken)
                    .clipShape(RoundedRectangle(cornerRadius: BakeRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(product.name)
                        .font(BakeFont.smallStrong)
                        .foregroundStyle(BakeColor.text)
                    Text(product.nameEn)
                        .font(BakeFont.tiny)
                        .foregroundStyle(BakeColor.muted)
                }

                Spacer(minLength: BakeSpace.s2)

                if let onEdit {
                    IconButton(icon: .edit, size: 34, iconSize: 15) {
                        onEdit(row.productId)
                    }
                }
            }

            HStack(spacing: BakeSpace.s2) {
                quantity("สั่ง", "\(row.expectedQty)", BakeColor.text)
                quantity("ตรวจพบ", row.detectedQty.map(String.init) ?? "—", BakeColor.text)
                quantity("ต่าง", BakeFormat.signed(row.difference), differenceColor)

                VStack(alignment: .leading, spacing: 4) {
                    Badge(text: Labels.comparison(row.status, difference: row.difference), tone: Labels.itemTone(row.status))
                    if corrected {
                        Text("แก้ไขเป็น \(row.manualQty ?? 0)")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.warningStrong)
                    } else if let confidence = row.confidence {
                        Text("ความมั่นใจ \(BakeFormat.percent(confidence))")
                            .font(BakeFont.tiny)
                            .foregroundStyle(BakeColor.muted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, BakeSpace.s3)
        .padding(.vertical, BakeSpace.s3)
        .background(background)
    }

    private var background: Color {
        switch row.status {
        case .missing, .extra: BakeColor.errorBg.opacity(0.45)
        case .uncertain: BakeColor.warningBg.opacity(0.45)
        case .match: BakeColor.surface
        case .pending: BakeColor.surface
        }
    }

    private var differenceColor: Color {
        guard let difference = row.difference else { return BakeColor.muted }
        if difference < 0 { return BakeColor.errorStrong }
        if difference > 0 { return BakeColor.warningStrong }
        return BakeColor.successStrong
    }

    private func quantity(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(BakeColor.muted)
        }
        .frame(width: 48)
    }
}
