document.addEventListener("DOMContentLoaded", function() {
    var canvas = document.getElementById("categoryChart");
    if (!canvas) return;

    var rawData = window.CATEGORIES_DATA || [];
    
    var labels = [];
    var dataValues = [];
    
    rawData.forEach(function(item) {
        labels.push(item.category);
        dataValues.push(item.quantity);
    });

    // Premium neon theme colors
    var themeColors = [
        '#38bdf8', // Cyan
        '#c084fc', // Purple
        '#4ade80', // Green
        '#fbbf24', // Yellow
        '#f87171', // Red
        '#a78bfa', // Violet
        '#64748b'  // Slate
    ];

    var ctx = canvas.getContext("2d");
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: dataValues,
                backgroundColor: themeColors.slice(0, labels.length),
                borderColor: '#0f172a', // Matches body background
                borderWidth: 2,
                hoverOffset: 6
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: {
                        color: '#f8fafc',
                        padding: 15,
                        font: {
                            family: 'Inter',
                            size: 11
                        }
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            var label = context.label || '';
                            var value = context.raw || 0;
                            return ' ' + label + ': ' + value + ' items';
                        }
                    }
                }
            },
            cutout: '65%'
        }
    });
});
