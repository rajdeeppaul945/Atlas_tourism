/**
 * Atlas Tourism - Admin Chart.js Visualizations
 * Loads monthly bookings, revenue trends, and top destinations dynamically.
 */

document.addEventListener('DOMContentLoaded', function () {
    const bookingChartEl = document.getElementById('monthlyBookingsChart');
    const revenueChartEl = document.getElementById('monthlyRevenueChart');
    const destinationChartEl = document.getElementById('destinationsChart');

    if (!bookingChartEl && !revenueChartEl && !destinationChartEl) return;

    fetch('/admin/api/chart-data')
        .then(res => res.json())
        .then(data => {
            // 1. Monthly Bookings Bar Chart
            if (bookingChartEl && data.bookings) {
                const labels = data.bookings.map(item => item.month_name);
                const counts = data.bookings.map(item => item.booking_count);

                new Chart(bookingChartEl, {
                    type: 'bar',
                    data: {
                        labels: labels.length ? labels : ['Current Year'],
                        datasets: [{
                            label: 'Bookings',
                            data: counts.length ? counts : [0],
                            backgroundColor: '#0d9488',
                            borderRadius: 8
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: { display: false }
                        },
                        scales: {
                            y: { beginAtZero: true, ticks: { precision: 0 } }
                        }
                    }
                });
            }

            // 2. Monthly Revenue Line Chart
            if (revenueChartEl && data.revenue) {
                const labels = data.revenue.map(item => item.month_name);
                const revenues = data.revenue.map(item => parseFloat(item.total_revenue));

                new Chart(revenueChartEl, {
                    type: 'line',
                    data: {
                        labels: labels.length ? labels : ['Current Year'],
                        datasets: [{
                            label: 'Revenue (₹)',
                            data: revenues.length ? revenues : [0],
                            borderColor: '#0284c7',
                            backgroundColor: 'rgba(2, 132, 199, 0.1)',
                            fill: true,
                            tension: 0.3,
                            borderWidth: 3
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: { display: false }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                ticks: {
                                    callback: function(value) { return '₹' + value.toLocaleString(); }
                                }
                            }
                        }
                    }
                });
            }

            // 3. Popular Destinations Doughnut Chart
            if (destinationChartEl && data.destinations) {
                const labels = data.destinations.map(item => item.destination_name);
                const counts = data.destinations.map(item => item.total_bookings);

                new Chart(destinationChartEl, {
                    type: 'doughnut',
                    data: {
                        labels: labels.length ? labels : ['No Bookings'],
                        datasets: [{
                            data: counts.length ? counts : [1],
                            backgroundColor: [
                                '#0d9488',
                                '#0284c7',
                                '#f59e0b',
                                '#ec4899',
                                '#8b5cf6'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: { position: 'bottom' }
                        }
                    }
                });
            }
        })
        .catch(err => console.error('Error fetching admin analytics:', err));
});
