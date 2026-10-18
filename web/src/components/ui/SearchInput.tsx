import { Icon } from '../icons/Icon'

interface SearchInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  label: string
  id?: string
}

export function SearchInput({ value, onChange, placeholder, label, id }: SearchInputProps) {
  return (
    <div className="search">
      <Icon name="search" size={17} className="search__icon" />
      <label className="visually-hidden" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        type="search"
        className="input"
        value={value}
        placeholder={placeholder}
        onChange={(event) => onChange(event.target.value)}
      />
      {value && (
        <button
          type="button"
          className="search__clear"
          onClick={() => onChange('')}
          aria-label="ล้างคำค้นหา"
        >
          <Icon name="x" size={15} />
        </button>
      )}
    </div>
  )
}
