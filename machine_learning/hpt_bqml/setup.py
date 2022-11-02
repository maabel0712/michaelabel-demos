from setuptools import setup

setup(name='trainer',
      version='1.0',
      description='Tune BigQuery ML',
      url='',
      author='Michael Abel',
      author_email='nobody@google.com',
      license='Apache2',
      packages=['trainer'],
      package_data={'': ['privatekey.json']},
      install_requires=[
          'google-cloud-bigquery==1.25.0',
          'cloudml-hypertune',  
      ],
      zip_safe=False)
