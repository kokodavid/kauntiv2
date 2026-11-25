import { assertEquals } from 'jsr:@std/assert@1'
import { bestOrder, Matrix, pathCost } from './order.ts'

// Points on a line: 0 is the start, the rest are scattered along it.
function lineMatrix(positions: number[]): Matrix {
  return positions.map((a) => positions.map((b) => Math.abs(a - b)))
}

Deno.test('a line is visited from the near end to the far end', () => {
  const matrix = lineMatrix([0, 30, 10, 20, 40])
  assertEquals(bestOrder(matrix), [2, 3, 1, 4])
})

Deno.test('the start never moves and every stop appears once', () => {
  const positions = [5, 9, 1, 14, 3, 11, 7, 2, 12]
  const order = bestOrder(lineMatrix(positions))
  assertEquals([...order].sort((a, b) => a - b), [1, 2, 3, 4, 5, 6, 7, 8])
})

Deno.test('never longer than the order the stops came in', () => {
  const positions = [0, 17, 4, 23, 9, 31, 2, 15, 28, 6, 20]
  const matrix = lineMatrix(positions)
  const given = positions.map((_, i) => i)
  const order = [0, ...bestOrder(matrix)]
  assertEquals(pathCost(matrix, order) <= pathCost(matrix, given), true)
})

Deno.test('one or two points', () => {
  assertEquals(bestOrder([[0]]), [])
  assertEquals(bestOrder([[0, 5], [5, 0]]), [1])
})

Deno.test('an unreachable pair is avoided when it can be', () => {
  const matrix: Matrix = [
    [0, 10, 10],
    [10, 0, null],
    [10, null, 0],
  ]
  const order = bestOrder(matrix)
  assertEquals(order.length, 2)
})
