import Chart from "chart.js/auto"
import "chartjs-adapter-date-fns"

export function initChart(canvasId, data, options = {}) {
  const canvas = document.getElementById(canvasId)
  if (!canvas) return null

  const ctx = canvas.getContext("2d")
  
  const defaultOptions = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: {
        type: "time",
        time: {
          unit: "minute",
          displayFormats: {
            minute: "HH:mm",
            hour: "HH:mm",
            day: "MMM dd"
          }
        }
      },
      y: {
        beginAtZero: false
      }
    },
    plugins: {
      legend: {
        display: true,
        position: "top"
      },
      tooltip: {
        mode: "index",
        intersect: false
      }
    }
  }

  return new Chart(ctx, {
    type: options.type || "line",
    data: data,
    options: { ...defaultOptions, ...options }
  })
}

export function updateChart(chart, newData) {
  if (!chart) return
  chart.data = newData
  chart.update()
}

export function destroyChart(chart) {
  if (chart) {
    chart.destroy()
  }
}

