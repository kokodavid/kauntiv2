// Puts a day's stops in a short driving order. Pure: it takes a matrix of
// driving times and returns the visiting order, so it can be tested alone.
//
// Point 0 is where the day starts and stays first. The path is open (the
// day ends at its last stop). Nearest neighbour gives a start, then 2-opt
// reversals shorten it until no reversal helps. With at most 21 points this
// is instant and close to the best order.

export type Matrix = (number | null)[][]

const UNREACHABLE = 1e9

function cost(matrix: Matrix, from: number, to: number): number {
  const value = matrix[from]?.[to]
  return typeof value === 'number' ? value : UNREACHABLE
}

export function pathCost(matrix: Matrix, order: number[]): number {
  let total = 0
  for (let i = 1; i < order.length; i++) total += cost(matrix, order[i - 1], order[i])
  return total
}

/** The order of point indexes 1..n-1 to visit, starting from point 0. */
export function bestOrder(matrix: Matrix): number[] {
  const n = matrix.length
  if (n <= 2) return n === 2 ? [1] : []

  // Nearest neighbour from the start.
  const left = new Set<number>()
  for (let i = 1; i < n; i++) left.add(i)
  let path = [0]
  while (left.size > 0) {
    const last = path[path.length - 1]
    let next = -1
    let nextCost = Infinity
    for (const candidate of left) {
      const c = cost(matrix, last, candidate)
      if (c < nextCost) {
        next = candidate
        nextCost = c
      }
    }
    path.push(next)
    left.delete(next)
  }

  // 2-opt: reverse a stretch whenever that shortens the whole path. Point 0
  // never moves.
  let improved = true
  while (improved) {
    improved = false
    const current = pathCost(matrix, path)
    for (let i = 1; i < n - 1 && !improved; i++) {
      for (let j = i + 1; j < n && !improved; j++) {
        const candidate = [
          ...path.slice(0, i),
          ...path.slice(i, j + 1).reverse(),
          ...path.slice(j + 1),
        ]
        if (pathCost(matrix, candidate) < current - 1e-9) {
          path = candidate
          improved = true
        }
      }
    }
  }
  return path.slice(1)
}
